package com.healthcare.hospital.mapper;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.Hospital;
import org.springframework.stereotype.Component;

@Component
public class HospitalMapper {

    public Hospital toEntity(HospitalCreateRequest request) {
        Hospital hospital = new Hospital();
        hospital.setName(request.name());
        hospital.setAddress(request.address());
        return hospital;
    }

    public void merge(Hospital hospital, HospitalUpdateRequest request) {
        hospital.setName(request.name());
        hospital.setAddress(request.address());
    }

    public HospitalResponse toResponse(Hospital hospital) {
        return new HospitalResponse(
                hospital.getId(),
                hospital.getName(),
                hospital.getAddress(),
                hospital.getStatus(),
                hospital.getCreatedAt(),
                hospital.getUpdatedAt()
        );
    }
}
