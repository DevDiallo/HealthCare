package com.healthcare.hospital.dto;

import com.healthcare.hospital.entity.HospitalStatus;

import java.time.Instant;
import java.util.UUID;

public record HospitalResponse(
        UUID id,
        String name,
        String address,
        HospitalStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
