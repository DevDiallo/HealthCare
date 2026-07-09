package com.healthcare.appointment.config;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    @NotBlank
    private String jwtSecret;

    @Positive
    private long jwtExpirationSeconds = 3600;

    @NotBlank
    private String patientServiceBaseUrl = "http://patient-service";

    @NotBlank
    private String doctorServiceBaseUrl = "http://doctor-service";

    public String getJwtSecret() {
        return jwtSecret;
    }

    public void setJwtSecret(String jwtSecret) {
        this.jwtSecret = jwtSecret;
    }

    public long getJwtExpirationSeconds() {
        return jwtExpirationSeconds;
    }

    public void setJwtExpirationSeconds(long jwtExpirationSeconds) {
        this.jwtExpirationSeconds = jwtExpirationSeconds;
    }

    public String getPatientServiceBaseUrl() {
        return patientServiceBaseUrl;
    }

    public void setPatientServiceBaseUrl(String patientServiceBaseUrl) {
        this.patientServiceBaseUrl = patientServiceBaseUrl;
    }

    public String getDoctorServiceBaseUrl() {
        return doctorServiceBaseUrl;
    }

    public void setDoctorServiceBaseUrl(String doctorServiceBaseUrl) {
        this.doctorServiceBaseUrl = doctorServiceBaseUrl;
    }
}
