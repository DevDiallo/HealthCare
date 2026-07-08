package com.healthcare.doctor.dto;

import java.time.Instant;
import java.util.UUID;

public record DoctorResponse(
        UUID id,
        UUID hospitalId,
        UUID userAccountId,
        String firstName,
        String lastName,
        String speciality,
        Instant createdAt,
        Instant updatedAt
) {
}
