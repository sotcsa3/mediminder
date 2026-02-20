package com.mediminder.security;

import com.mediminder.config.JwtProperties;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
@RequiredArgsConstructor
@Slf4j
public class JwtTokenProvider {

    private static final int MIN_SECRET_LENGTH = 32; // 256 bits minimum for HS256
    private final JwtProperties jwtProperties;
    private SecretKey secretKey;

    @PostConstruct
    public void init() {
        validateSecret();
        this.secretKey = Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    private void validateSecret() {
        if (jwtProperties.getSecret() == null || jwtProperties.getSecret().isBlank()) {
            throw new IllegalStateException(
                    "JWT_SECRET environment variable is not set. Please configure a secure secret key.");
        }

        if (jwtProperties.getSecret().length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                    String.format("JWT secret key is too weak. Minimum length is %d characters (256 bits). " +
                            "Current length: %d characters. Please configure a stronger secret key.",
                            MIN_SECRET_LENGTH, jwtProperties.getSecret().length()));
        }

        // Warn about default/weak secrets in non-production environments
        if (jwtProperties.getSecret().contains("change-in-production") ||
                jwtProperties.getSecret().equals("mediminder-jwt-secret-key-change-in-production-min-256-bits")) {
            log.warn("⚠️  WARNING: Using default JWT secret! This is insecure for production. " +
                    "Please set a strong JWT_SECRET environment variable.");
        }
    }

    public String generateToken(String userId, String email) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtProperties.getExpiration());

        return Jwts.builder()
                .subject(userId)
                .claim("email", email)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(secretKey)
                .compact();
    }

    public String getUserIdFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }

    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.get("email", String.class);
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.error("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }
}
