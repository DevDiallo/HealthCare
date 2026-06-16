package com.healthcare.auth.dto;

import com.healthcare.auth.entity.Role;
import lombok.Builder;

@Builder
public record TokenResponse(
        String accessToken,
        String refreshToken,
        Long userId,
        Long hospitalId,
        Role role,
        String tokenType,
        long expiresIn
) {
}