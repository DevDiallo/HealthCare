package com.healthcare.notification.dto;

import com.healthcare.notification.entity.NotificationStatus;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        UUID hospitalId,
        UUID recipientUserId,
        String title,
        String message,
        NotificationStatus status,
        Instant sentAt,
        Instant createdAt,
        Instant updatedAt
) {
}
