package com.mediminder.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    
    private String token;
    private String userId;
    private String email;
    private String fullName;
    private String message;
}
