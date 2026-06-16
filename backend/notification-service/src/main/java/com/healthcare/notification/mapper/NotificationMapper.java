package com.healthcare.notification.mapper;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.entity.Notification;
import org.springframework.stereotype.Component;

@Component
public class NotificationMapper {

    public Notification toEntity(NotificationCreateRequest request) {
        Notification notification = new Notification();
        notification.setRecipientUserId(request.recipientUserId());
        notification.setTitle(request.title());
        notification.setMessage(request.message());
        return notification;
    }

    public void merge(Notification notification, NotificationUpdateRequest request) {
        notification.setRecipientUserId(request.recipientUserId());
        notification.setTitle(request.title());
        notification.setMessage(request.message());
    }

    public NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getHospitalId(),
                notification.getRecipientUserId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getStatus(),
                notification.getSentAt(),
                notification.getCreatedAt(),
                notification.getUpdatedAt()
        );
    }
}
