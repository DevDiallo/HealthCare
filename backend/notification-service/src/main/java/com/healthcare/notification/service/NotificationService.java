package com.healthcare.notification.service;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.util.PageResponse;

import java.util.UUID;

public interface NotificationService {

    NotificationResponse create(NotificationCreateRequest request);

    NotificationResponse getById(UUID id);

    NotificationResponse update(UUID id, NotificationUpdateRequest request);

    void delete(UUID id);

    NotificationResponse send(UUID id);

    PageResponse<NotificationResponse> list(int page, int size, String sort);
}
