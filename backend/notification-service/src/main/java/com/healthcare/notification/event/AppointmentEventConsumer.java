package com.healthcare.notification.event;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.healthcare.notification.entity.Notification;
import com.healthcare.notification.entity.NotificationStatus;
import com.healthcare.notification.repository.NotificationRepository;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Component
public class AppointmentEventConsumer {

    private final ObjectMapper objectMapper;
    private final NotificationRepository notificationRepository;

    public AppointmentEventConsumer(ObjectMapper objectMapper, NotificationRepository notificationRepository) {
        this.objectMapper = objectMapper;
        this.notificationRepository = notificationRepository;
    }

    @KafkaListener(topics = "${app.kafka.appointment-topic:appointment-events}")
    @Transactional
    public void consume(String payload) {
        AppointmentEvent event;
        try {
            event = objectMapper.readValue(payload, AppointmentEvent.class);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to deserialize appointment event", ex);
        }

        if (event.hospitalId() == null) {
            return;
        }

        String title = switch (event.eventType()) {
            case "APPOINTMENT_CREATED" -> "Nouveau rendez-vous";
            case "APPOINTMENT_UPDATED" -> "Rendez-vous modifié";
            case "APPOINTMENT_CONFIRMED" -> "Rendez-vous confirmé";
            case "APPOINTMENT_CANCELLED" -> "Rendez-vous annulé";
            default -> "Mise à jour rendez-vous";
        };

        String message = "Rendez-vous " + event.appointmentId() + " - statut: " + event.status()
                + " - date: " + event.appointmentAt();

        List<UUID> recipients = new ArrayList<>();
        if (event.patientId() != null) {
            recipients.add(event.patientId());
        }
        if (event.doctorId() != null) {
            recipients.add(event.doctorId());
        }

        for (UUID recipient : recipients) {
            Notification notification = new Notification();
            notification.setHospitalId(event.hospitalId());
            notification.setRecipientUserId(recipient);
            notification.setTitle(title);
            notification.setMessage(message);
            notification.setStatus(NotificationStatus.NEW);
            notificationRepository.save(notification);
        }
    }
}