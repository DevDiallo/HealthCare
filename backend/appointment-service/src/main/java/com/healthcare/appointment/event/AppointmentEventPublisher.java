package com.healthcare.appointment.event;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
public class AppointmentEventPublisher {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final String topic;

    public AppointmentEventPublisher(
            KafkaTemplate<String, String> kafkaTemplate,
            ObjectMapper objectMapper,
            @Value("${app.kafka.appointment-topic:appointment-events}") String topic
    ) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.topic = topic;
    }

    public void publish(AppointmentEvent event) {
        try {
            String payload = objectMapper.writeValueAsString(event);
            String key = event.hospitalId() == null ? "global" : event.hospitalId().toString();
            kafkaTemplate.send(topic, key, payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to serialize appointment event", ex);
        }
    }
}