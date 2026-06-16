package com.healthcare.patient.dto;

import java.time.Instant;
import java.util.UUID;

public record PatientResponse(
        UUID id,
        UUID hospitalId,
        String firstName,
        String lastName,
        String email,
        Instant createdAt,
        Instant updatedAt
) {
}
