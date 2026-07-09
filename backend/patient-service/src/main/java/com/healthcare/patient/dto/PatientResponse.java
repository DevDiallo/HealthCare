package com.healthcare.patient.dto;

import java.time.Instant;
import java.util.UUID;

public record PatientResponse(
        UUID id,
        UUID hospitalId,
        UUID userAccountId,
        UUID assignedDoctorUserId,
        String firstName,
        String lastName,
        String email,
        String bloodType,
        String allergies,
        String chronicConditions,
        String emergencyContact,
        Instant createdAt,
        Instant updatedAt
) {
}
