package com.healthcare.patient.service;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.util.PageResponse;

import java.util.UUID;

public interface PatientService {

    PatientResponse create(PatientCreateRequest request);

    PatientResponse getById(UUID id);

    PatientResponse update(UUID id, PatientUpdateRequest request);

    void delete(UUID id);

    PageResponse<PatientResponse> list(String search, int page, int size, String sort);
}
