package com.healthcare.doctor.mapper;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.entity.Doctor;
import org.springframework.stereotype.Component;

@Component
public class DoctorMapper {

    public Doctor toEntity(DoctorCreateRequest request) {
        Doctor doctor = new Doctor();
        doctor.setFirstName(request.firstName());
        doctor.setLastName(request.lastName());
        doctor.setSpeciality(request.speciality());
        return doctor;
    }

    public void merge(Doctor doctor, DoctorUpdateRequest request) {
        doctor.setFirstName(request.firstName());
        doctor.setLastName(request.lastName());
        doctor.setSpeciality(request.speciality());
    }

    public DoctorResponse toResponse(Doctor doctor) {
        return new DoctorResponse(
                doctor.getId(),
                doctor.getHospitalId(),
                doctor.getFirstName(),
                doctor.getLastName(),
                doctor.getSpeciality(),
                doctor.getCreatedAt(),
                doctor.getUpdatedAt()
        );
    }
}
