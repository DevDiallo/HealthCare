package com.healthcare.notification.event;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentEvent(
        String eventType,
        UUID appointmentId,
        UUID hospitalId,
        UUID patientId,
        UUID doctorId,
        String status,
        LocalDateTime appointmentAt,
        Instant occurredAt
) {
}