package com.healthcare.doctor.service;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.util.PageResponse;

import java.util.UUID;

public interface DoctorService {

    DoctorResponse create(DoctorCreateRequest request);

    DoctorResponse getById(UUID id);

    DoctorResponse getByUserAccountId(UUID userAccountId);

    DoctorResponse update(UUID id, DoctorUpdateRequest request);

    void delete(UUID id);

    PageResponse<DoctorResponse> list(String search, String speciality, int page, int size, String sort);
}
