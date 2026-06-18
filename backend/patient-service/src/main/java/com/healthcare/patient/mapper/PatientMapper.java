package com.healthcare.patient.mapper;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.entity.Patient;
import org.springframework.stereotype.Component;

@Component
public class PatientMapper {

    public Patient toEntity(PatientCreateRequest request) {
        Patient patient = new Patient();
        patient.setFirstName(request.firstName());
        patient.setLastName(request.lastName());
        patient.setEmail(request.email());
        patient.setBloodType(request.bloodType());
        patient.setAllergies(request.allergies());
        patient.setChronicConditions(request.chronicConditions());
        patient.setEmergencyContact(request.emergencyContact());
        return patient;
    }

    public void merge(Patient patient, PatientUpdateRequest request) {
        patient.setFirstName(request.firstName());
        patient.setLastName(request.lastName());
        patient.setEmail(request.email());
        patient.setBloodType(request.bloodType());
        patient.setAllergies(request.allergies());
        patient.setChronicConditions(request.chronicConditions());
        patient.setEmergencyContact(request.emergencyContact());
    }

    public PatientResponse toResponse(Patient patient) {
        return new PatientResponse(
                patient.getId(),
                patient.getHospitalId(),
                patient.getFirstName(),
                patient.getLastName(),
                patient.getEmail(),
                patient.getBloodType(),
                patient.getAllergies(),
                patient.getChronicConditions(),
                patient.getEmergencyContact(),
                patient.getCreatedAt(),
                patient.getUpdatedAt()
        );
    }
}
