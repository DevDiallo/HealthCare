package com.healthcare.auth.dto;

import com.healthcare.auth.entity.Role;
import com.healthcare.auth.entity.UserStatus;
import lombok.Builder;

import java.time.OffsetDateTime;

@Builder
public record UserResponse(
        Long id,
        String firstName,
        String lastName,
        String email,
        String phone,
        Long hospitalId,
        Role role,
        UserStatus status,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
) {
}