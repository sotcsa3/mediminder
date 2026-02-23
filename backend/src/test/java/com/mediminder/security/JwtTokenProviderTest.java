package com.mediminder.security;

import com.mediminder.config.JwtProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class JwtTokenProviderTest {

    private JwtTokenProvider tokenProvider;
    private static final String VALID_SECRET = "this-is-a-very-long-and-secure-jwt-secret-key-for-testing-256-bits";

    @BeforeEach
    void setUp() {
        JwtProperties props = new JwtProperties();
        props.setSecret(VALID_SECRET);
        props.setExpiration(86400000L); // 24 hours
        tokenProvider = new JwtTokenProvider(props);
        tokenProvider.init();
    }

    @Nested
    @DisplayName("Token Generation")
    class GenerateTokenTests {

        @Test
        @DisplayName("should generate a non-null JWT token")
        void generateTokenSuccess() {
            String token = tokenProvider.generateToken("user-123", "test@example.com");

            assertThat(token).isNotNull().isNotEmpty();
            // JWT format: header.payload.signature
            assertThat(token.split("\\.")).hasSize(3);
        }

        @Test
        @DisplayName("should generate unique tokens for different users")
        void generateTokenUnique() {
            String token1 = tokenProvider.generateToken("user-1", "a@example.com");
            String token2 = tokenProvider.generateToken("user-2", "b@example.com");

            assertThat(token1).isNotEqualTo(token2);
        }
    }

    @Nested
    @DisplayName("Token Parsing")
    class ParseTokenTests {

        @Test
        @DisplayName("should extract userId from token")
        void getUserIdFromToken() {
            String token = tokenProvider.generateToken("user-123", "test@example.com");

            String userId = tokenProvider.getUserIdFromToken(token);

            assertThat(userId).isEqualTo("user-123");
        }

        @Test
        @DisplayName("should extract email from token")
        void getEmailFromToken() {
            String token = tokenProvider.generateToken("user-123", "test@example.com");

            String email = tokenProvider.getEmailFromToken(token);

            assertThat(email).isEqualTo("test@example.com");
        }
    }

    @Nested
    @DisplayName("Token Validation")
    class ValidateTokenTests {

        @Test
        @DisplayName("should validate a legitimate token")
        void validateTokenSuccess() {
            String token = tokenProvider.generateToken("user-123", "test@example.com");

            assertThat(tokenProvider.validateToken(token)).isTrue();
        }

        @Test
        @DisplayName("should reject an invalid token")
        void validateTokenInvalid() {
            assertThat(tokenProvider.validateToken("invalid-token")).isFalse();
        }

        @Test
        @DisplayName("should reject a tampered token")
        void validateTokenTampered() {
            String token = tokenProvider.generateToken("user-123", "test@example.com");
            String tampered = token.substring(0, token.length() - 5) + "XXXXX";

            assertThat(tokenProvider.validateToken(tampered)).isFalse();
        }

        @Test
        @DisplayName("should reject a token signed with different secret")
        void validateTokenDifferentSecret() {
            // Generate token with different secret
            JwtProperties otherProps = new JwtProperties();
            otherProps.setSecret("another-very-long-and-secure-jwt-secret-key-for-testing-256-bits");
            otherProps.setExpiration(86400000L);
            JwtTokenProvider otherProvider = new JwtTokenProvider(otherProps);
            otherProvider.init();

            String tokenFromOther = otherProvider.generateToken("user-123", "test@example.com");

            assertThat(tokenProvider.validateToken(tokenFromOther)).isFalse();
        }

        @Test
        @DisplayName("should reject expired token")
        void validateExpiredToken() {
            JwtProperties shortLivedProps = new JwtProperties();
            shortLivedProps.setSecret(VALID_SECRET);
            shortLivedProps.setExpiration(0L); // 0ms = immediately expired
            JwtTokenProvider shortLivedProvider = new JwtTokenProvider(shortLivedProps);
            shortLivedProvider.init();

            String token = shortLivedProvider.generateToken("user-123", "test@example.com");

            assertThat(tokenProvider.validateToken(token)).isFalse();
        }

        @Test
        @DisplayName("should reject null token")
        void validateNullToken() {
            assertThat(tokenProvider.validateToken(null)).isFalse();
        }

        @Test
        @DisplayName("should reject empty token")
        void validateEmptyToken() {
            assertThat(tokenProvider.validateToken("")).isFalse();
        }
    }

    @Nested
    @DisplayName("Secret Validation")
    class SecretValidationTests {

        @Test
        @DisplayName("should reject null secret")
        void rejectNullSecret() {
            JwtProperties props = new JwtProperties();
            props.setSecret(null);
            props.setExpiration(86400000L);
            JwtTokenProvider provider = new JwtTokenProvider(props);

            assertThatThrownBy(provider::init)
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("not set");
        }

        @Test
        @DisplayName("should reject secret shorter than 32 chars")
        void rejectShortSecret() {
            JwtProperties props = new JwtProperties();
            props.setSecret("too-short");
            props.setExpiration(86400000L);
            JwtTokenProvider provider = new JwtTokenProvider(props);

            assertThatThrownBy(provider::init)
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("too weak");
        }

        @Test
        @DisplayName("should reject blank secret")
        void rejectBlankSecret() {
            JwtProperties props = new JwtProperties();
            props.setSecret("   ");
            props.setExpiration(86400000L);
            JwtTokenProvider provider = new JwtTokenProvider(props);

            assertThatThrownBy(provider::init)
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("not set");
        }
    }
}
