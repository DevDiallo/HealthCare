package com.healthcare.doctor.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record DoctorCreateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @NotBlank(message = "speciality is required") String speciality
) {
}
