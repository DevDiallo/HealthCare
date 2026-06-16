package com.healthcare.notification.controller;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.service.NotificationService;
import com.healthcare.notification.util.ApiResponse;
import com.healthcare.notification.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @PostMapping
    public ApiResponse<NotificationResponse> create(@Valid @RequestBody NotificationCreateRequest request) {
        return ApiResponse.ok("Notification created", notificationService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<NotificationResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Notification fetched", notificationService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<NotificationResponse> update(@PathVariable UUID id, @Valid @RequestBody NotificationUpdateRequest request) {
        return ApiResponse.ok("Notification updated", notificationService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        notificationService.delete(id);
        return ApiResponse.ok("Notification deleted", null);
    }

    @PatchMapping("/{id}/send")
    public ApiResponse<NotificationResponse> send(@PathVariable UUID id) {
        return ApiResponse.ok("Notification sent", notificationService.send(id));
    }

    @GetMapping
    public ApiResponse<PageResponse<NotificationResponse>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Notifications listed", notificationService.list(page, size, sort));
    }
}
