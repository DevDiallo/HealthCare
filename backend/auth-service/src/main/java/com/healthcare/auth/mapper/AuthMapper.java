package com.healthcare.auth.mapper;

import com.healthcare.auth.dto.RegisterRequest;
import com.healthcare.auth.dto.UserResponse;
import com.healthcare.auth.entity.UserAccount;
import com.healthcare.auth.entity.UserStatus;

public final class AuthMapper {

    private AuthMapper() {
    }

    public static UserAccount toEntity(RegisterRequest request, String encodedPassword) {
        return UserAccount.builder()
                .firstName(request.firstName())
                .lastName(request.lastName())
                .email(request.email().toLowerCase())
                .password(encodedPassword)
                .phone(request.phone())
                .hospitalId(request.hospitalId())
                .role(request.role())
                .status(UserStatus.ACTIVE)
                .build();
    }

    public static UserResponse toResponse(UserAccount user) {
        return UserResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .hospitalId(user.getHospitalId())
                .role(user.getRole())
                .status(user.getStatus())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}