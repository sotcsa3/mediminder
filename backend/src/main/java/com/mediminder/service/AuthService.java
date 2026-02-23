package com.mediminder.service;

import com.mediminder.dto.AuthRequest;
import com.mediminder.dto.AuthResponse;
import com.mediminder.entity.User;
import com.mediminder.repository.UserRepository;
import com.mediminder.exception.AuthenticationException;
import com.mediminder.exception.ConflictException;
import com.mediminder.exception.ResourceNotFoundException;
import com.mediminder.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    @Transactional
    public AuthResponse register(AuthRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email already registered");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getEmail().split("@")[0])
                .provider("local")
                .build();

        user = userRepository.save(user);

        String token = tokenProvider.generateToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .message("Registration successful")
                .build();
    }

    @Transactional
    public AuthResponse login(AuthRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AuthenticationException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new AuthenticationException("Invalid email or password");
        }

        String token = tokenProvider.generateToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .message("Login successful")
                .build();
    }

    @Transactional
    public AuthResponse handleGoogleLogin(String email, String googleId, String fullName) {
        User user = userRepository.findByProviderAndProviderId("google", googleId)
                .orElseGet(() -> {
                    // Check if user exists with this email
                    return userRepository.findByEmail(email)
                            .map(existingUser -> {
                                // If the existing account uses a different provider, reject the login
                                if (!"google".equals(existingUser.getProvider())) {
                                    throw new ConflictException(
                                            "An account with this email already exists. Please log in with your password.");
                                }
                                return existingUser;
                            })
                            .orElseGet(() -> {
                                // Create new user
                                User newUser = User.builder()
                                        .email(email)
                                        .provider("google")
                                        .providerId(googleId)
                                        .fullName(fullName != null ? fullName : email.split("@")[0])
                                        .build();
                                return userRepository.save(newUser);
                            });
                });

        // Update provider info only for existing Google users
        if ("google".equals(user.getProvider()) && user.getProviderId() != null) {
            if (fullName != null && !fullName.equals(user.getFullName())) {
                user.setFullName(fullName);
                userRepository.save(user);
            }
        }

        String token = tokenProvider.generateToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .message("Google login successful")
                .build();
    }

    public User getUserById(String userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}
