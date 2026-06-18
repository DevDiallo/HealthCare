package com.healthcare.patient.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record PatientCreateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @Email(message = "email is invalid") @NotBlank(message = "email is required") String email,
        String bloodType,
        String allergies,
        String chronicConditions,
        String emergencyContact
) {
}
