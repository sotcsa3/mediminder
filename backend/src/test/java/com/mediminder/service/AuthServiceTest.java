package com.mediminder.service;

import com.mediminder.dto.AuthRequest;
import com.mediminder.dto.AuthResponse;
import com.mediminder.entity.User;
import com.mediminder.exception.AuthenticationException;
import com.mediminder.exception.ConflictException;
import com.mediminder.exception.ResourceNotFoundException;
import com.mediminder.repository.UserRepository;
import com.mediminder.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider tokenProvider;

    @InjectMocks
    private AuthService authService;

    private User testUser;
    private AuthRequest authRequest;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id("user-123")
                .email("test@example.com")
                .password("encoded-password")
                .fullName("test")
                .provider("local")
                .build();

        authRequest = new AuthRequest();
        authRequest.setEmail("test@example.com");
        authRequest.setPassword("password123");
    }

    @Nested
    @DisplayName("Register")
    class RegisterTests {

        @Test
        @DisplayName("should register a new user successfully")
        void registerSuccess() {
            when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
            when(passwordEncoder.encode("password123")).thenReturn("encoded-password");
            when(userRepository.save(any(User.class))).thenReturn(testUser);
            when(tokenProvider.generateToken("user-123", "test@example.com")).thenReturn("jwt-token");

            AuthResponse response = authService.register(authRequest);

            assertThat(response.getToken()).isEqualTo("jwt-token");
            assertThat(response.getUserId()).isEqualTo("user-123");
            assertThat(response.getEmail()).isEqualTo("test@example.com");
            assertThat(response.getMessage()).isEqualTo("Registration successful");
            verify(userRepository).save(any(User.class));
        }

        @Test
        @DisplayName("should throw ConflictException when email already exists")
        void registerDuplicateEmail() {
            when(userRepository.existsByEmail("test@example.com")).thenReturn(true);

            assertThatThrownBy(() -> authService.register(authRequest))
                    .isInstanceOf(ConflictException.class)
                    .hasMessage("Email already registered");

            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("should derive fullName from email")
        void registerDeriveFullName() {
            when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("encoded");
            when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
                User saved = invocation.getArgument(0);
                saved.setId("user-new");
                assertThat(saved.getFullName()).isEqualTo("test");
                return saved;
            });
            when(tokenProvider.generateToken(anyString(), anyString())).thenReturn("token");

            authService.register(authRequest);

            verify(userRepository).save(argThat(user -> "test".equals(user.getFullName())));
        }
    }

    @Nested
    @DisplayName("Login")
    class LoginTests {

        @Test
        @DisplayName("should login with correct credentials")
        void loginSuccess() {
            when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
            when(passwordEncoder.matches("password123", "encoded-password")).thenReturn(true);
            when(tokenProvider.generateToken("user-123", "test@example.com")).thenReturn("jwt-token");

            AuthResponse response = authService.login(authRequest);

            assertThat(response.getToken()).isEqualTo("jwt-token");
            assertThat(response.getUserId()).isEqualTo("user-123");
            assertThat(response.getMessage()).isEqualTo("Login successful");
        }

        @Test
        @DisplayName("should throw AuthenticationException for invalid email")
        void loginInvalidEmail() {
            when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.login(authRequest))
                    .isInstanceOf(AuthenticationException.class)
                    .hasMessage("Invalid email or password");
        }

        @Test
        @DisplayName("should throw AuthenticationException for wrong password")
        void loginWrongPassword() {
            when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
            when(passwordEncoder.matches("password123", "encoded-password")).thenReturn(false);

            assertThatThrownBy(() -> authService.login(authRequest))
                    .isInstanceOf(AuthenticationException.class)
                    .hasMessage("Invalid email or password");
        }
    }

    @Nested
    @DisplayName("Google Login")
    class GoogleLoginTests {

        @Test
        @DisplayName("should create new user on first Google login")
        void googleLoginNewUser() {
            when(userRepository.findByProviderAndProviderId("google", "google-id-123"))
                    .thenReturn(Optional.empty());
            when(userRepository.findByEmail("google@example.com")).thenReturn(Optional.empty());
            User newUser = User.builder()
                    .id("new-user")
                    .email("google@example.com")
                    .fullName("Google User")
                    .provider("google")
                    .providerId("google-id-123")
                    .build();
            when(userRepository.save(any(User.class))).thenReturn(newUser);
            when(tokenProvider.generateToken("new-user", "google@example.com")).thenReturn("google-jwt");

            AuthResponse response = authService.handleGoogleLogin("google@example.com", "google-id-123", "Google User");

            assertThat(response.getToken()).isEqualTo("google-jwt");
            assertThat(response.getEmail()).isEqualTo("google@example.com");
            assertThat(response.getMessage()).isEqualTo("Google login successful");
        }

        @Test
        @DisplayName("should return existing Google user")
        void googleLoginExistingUser() {
            User existingUser = User.builder()
                    .id("existing-user")
                    .email("google@example.com")
                    .fullName("Google User")
                    .provider("google")
                    .providerId("google-id-123")
                    .build();
            when(userRepository.findByProviderAndProviderId("google", "google-id-123"))
                    .thenReturn(Optional.of(existingUser));
            when(tokenProvider.generateToken("existing-user", "google@example.com")).thenReturn("google-jwt");

            AuthResponse response = authService.handleGoogleLogin("google@example.com", "google-id-123", "Google User");

            assertThat(response.getToken()).isEqualTo("google-jwt");
            assertThat(response.getUserId()).isEqualTo("existing-user");
        }

        @Test
        @DisplayName("should reject Google login when email exists with local provider")
        void googleLoginConflictWithLocalUser() {
            User localUser = User.builder()
                    .id("local-user")
                    .email("test@example.com")
                    .provider("local")
                    .build();
            when(userRepository.findByProviderAndProviderId("google", "google-id-123"))
                    .thenReturn(Optional.empty());
            when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(localUser));

            assertThatThrownBy(() -> authService.handleGoogleLogin("test@example.com", "google-id-123", "Test User"))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("already exists");
        }
    }

    @Nested
    @DisplayName("User Lookup")
    class UserLookupTests {

        @Test
        @DisplayName("should find user by ID")
        void getUserByIdSuccess() {
            when(userRepository.findById("user-123")).thenReturn(Optional.of(testUser));

            User user = authService.getUserById("user-123");

            assertThat(user.getId()).isEqualTo("user-123");
            assertThat(user.getEmail()).isEqualTo("test@example.com");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException for missing user ID")
        void getUserByIdNotFound() {
            when(userRepository.findById("nonexistent")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.getUserById("nonexistent"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("User not found");
        }

        @Test
        @DisplayName("should find user by email")
        void getUserByEmailSuccess() {
            when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));

            User user = authService.getUserByEmail("test@example.com");

            assertThat(user.getEmail()).isEqualTo("test@example.com");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException for missing email")
        void getUserByEmailNotFound() {
            when(userRepository.findByEmail("missing@example.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.getUserByEmail("missing@example.com"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("User not found");
        }
    }
}
