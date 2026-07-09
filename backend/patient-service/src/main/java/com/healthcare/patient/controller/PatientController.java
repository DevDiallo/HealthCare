package com.healthcare.patient.controller;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.service.PatientService;
import com.healthcare.patient.util.ApiResponse;
import com.healthcare.patient.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;

    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    @PostMapping({"", "/"})
    public ApiResponse<PatientResponse> create(@Valid @RequestBody PatientCreateRequest request) {
        return ApiResponse.ok("Patient created", patientService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<PatientResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Patient fetched", patientService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<PatientResponse> update(@PathVariable UUID id, @Valid @RequestBody PatientUpdateRequest request) {
        return ApiResponse.ok("Patient updated", patientService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        patientService.delete(id);
        return ApiResponse.ok("Patient deleted", null);
    }

    @GetMapping({"", "/"})
    public ApiResponse<PageResponse<PatientResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Patients listed", patientService.list(search, page, size, sort));
    }
}
