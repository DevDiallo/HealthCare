package com.healthcare.appointment.client;

import com.healthcare.appointment.config.AppProperties;
import com.healthcare.appointment.exception.NotFoundException;
import com.healthcare.appointment.exception.UnauthorizedException;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.UUID;
import java.util.Objects;

@Component
public class PatientServiceClient {

    private final RestClient restClient;

    public PatientServiceClient(AppProperties properties, RestClient.Builder restClientBuilder) {
        String baseUrl = Objects.requireNonNull(properties.getPatientServiceBaseUrl(), "patientServiceBaseUrl");
        this.restClient = restClientBuilder
            .baseUrl(baseUrl)
                .build();
    }

    public void ensurePatientExists(UUID patientId) {
        try {
            restClient.get()
                    .uri("/api/patients/{id}", patientId)
                    .headers(headers -> {
                        String authorization = currentAuthorizationHeader();
                        if (authorization != null) {
                            headers.set(HttpHeaders.AUTHORIZATION, authorization);
                        }
                    })
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                throw new NotFoundException("Patient not found: " + patientId);
            }
            if (ex.getStatusCode().value() == 401 || ex.getStatusCode().value() == 403) {
                throw new UnauthorizedException("Unable to validate patient");
            }
            throw new IllegalStateException("Patient service unavailable", ex);
        }
    }

    private String currentAuthorizationHeader() {
        var attributes = RequestContextHolder.getRequestAttributes();
        if (!(attributes instanceof ServletRequestAttributes servletRequestAttributes)) {
            return null;
        }
        return servletRequestAttributes.getRequest().getHeader(HttpHeaders.AUTHORIZATION);
    }
}