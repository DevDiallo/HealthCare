package com.healthcare.hospital.service;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.HospitalStatus;
import com.healthcare.hospital.util.PageResponse;

import java.util.UUID;

public interface HospitalService {

    HospitalResponse create(HospitalCreateRequest request);

    HospitalResponse getById(UUID id);

    HospitalResponse update(UUID id, HospitalUpdateRequest request);

    void delete(UUID id);

    HospitalResponse activate(UUID id);

    HospitalResponse suspend(UUID id);

    PageResponse<HospitalResponse> list(String search, HospitalStatus status, int page, int size, String sort);
}
