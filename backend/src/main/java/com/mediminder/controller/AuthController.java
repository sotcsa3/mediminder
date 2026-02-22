package com.mediminder.controller;

import com.mediminder.dto.AuthRequest;
import com.mediminder.dto.AuthResponse;
import com.mediminder.entity.User;
import com.mediminder.security.UserPrincipal;
import com.mediminder.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody AuthRequest request) {
        log.info("Register request for email: {}", maskEmail(request.getEmail()));
        AuthResponse response = authService.register(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody AuthRequest request) {
        log.info("Login request for email: {}", maskEmail(request.getEmail()));
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> googleLogin(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String googleId = request.get("googleId");
        String fullName = request.get("fullName");

        if (email == null || email.isBlank() || googleId == null || googleId.isBlank()) {
            return ResponseEntity.badRequest().body(AuthResponse.builder()
                    .message("Email and googleId are required")
                    .build());
        }

        log.info("Google login request for email: {}", maskEmail(email));
        AuthResponse response = authService.handleGoogleLogin(email, googleId, fullName);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@AuthenticationPrincipal UserPrincipal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Not authenticated"));
        }

        User user = authService.getUserById(principal.getUserId());
        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "email", user.getEmail(),
                "fullName", user.getFullName()));
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "***";
        }
        String[] parts = email.split("@");
        String local = parts[0];
        String domain = parts[1];
        if (local.length() <= 2) {
            return "***@" + domain;
        }
        return local.charAt(0) + "***" + local.charAt(local.length() - 1) + "@" + domain;
    }
}
