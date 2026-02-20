package com.mediminder.service;

import com.mediminder.dto.AuthRequest;
import com.mediminder.dto.AuthResponse;
import com.mediminder.entity.User;
import com.mediminder.repository.UserRepository;
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
            throw new RuntimeException("Email already registered");
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
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));
        
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
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
        
        // Update provider info if needed
        if (user.getProvider() == null || !user.getProvider().equals("google")) {
            user.setProvider("google");
            user.setProviderId(googleId);
            if (fullName != null) {
                user.setFullName(fullName);
            }
            userRepository.save(user);
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
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
    
    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
