package com.healthcare.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record NotificationCreateRequest(
        UUID hospitalId,
        @NotNull(message = "recipientUserId is required") UUID recipientUserId,
        @NotBlank(message = "title is required") String title,
        @NotBlank(message = "message is required") String message
) {
}
