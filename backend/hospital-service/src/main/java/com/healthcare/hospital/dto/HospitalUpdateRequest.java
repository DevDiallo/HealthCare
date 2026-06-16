package com.healthcare.hospital.dto;

import jakarta.validation.constraints.NotBlank;

public record HospitalUpdateRequest(
        @NotBlank(message = "name is required") String name,
        @NotBlank(message = "address is required") String address
) {
}
