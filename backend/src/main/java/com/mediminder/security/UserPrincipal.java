package com.mediminder.security;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserPrincipal {
    
    private final String userId;
    private final String email;
}
