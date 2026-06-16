package com.healthcare.appointment.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentUpdateRequest(
        UUID hospitalId,
        @NotNull(message = "patientId is required") UUID patientId,
        @NotNull(message = "doctorId is required") UUID doctorId,
        @NotNull(message = "appointmentAt is required") @Future(message = "appointmentAt must be future") LocalDateTime appointmentAt
) {
}
