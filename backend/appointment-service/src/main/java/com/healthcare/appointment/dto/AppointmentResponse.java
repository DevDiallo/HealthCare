package com.healthcare.appointment.dto;

import com.healthcare.appointment.entity.AppointmentStatus;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentResponse(
        UUID id,
        UUID hospitalId,
        UUID patientId,
        UUID doctorId,
        LocalDateTime appointmentAt,
        AppointmentStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
