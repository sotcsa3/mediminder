package com.mediminder.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;

/**
 * Verifies Google ID tokens server-side using Google's public keys.
 * This prevents authentication bypass by ensuring tokens are genuinely
 * issued by Google for our application's client ID.
 */
@Service
@Slf4j
public class GoogleTokenVerifierService {

    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private String googleClientId;

    private GoogleIdTokenVerifier verifier;

    @PostConstruct
    public void init() {
        this.verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(Collections.singletonList(googleClientId))
                .build();
        log.info("GoogleTokenVerifierService initialized with client ID: {}...",
                googleClientId.substring(0, Math.min(8, googleClientId.length())));
    }

    /**
     * Verifies a Google ID token and returns the payload if valid.
     *
     * @param idTokenString The raw Google ID token (JWT) from the client
     * @return The verified token payload, or null if verification fails
     */
    public GoogleIdToken.Payload verify(String idTokenString) {
        try {
            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken != null) {
                return idToken.getPayload();
            }
            log.warn("Google ID token verification failed: token is invalid or expired");
            return null;
        } catch (Exception e) {
            log.error("Error verifying Google ID token: {}", e.getMessage());
            return null;
        }
    }
}
