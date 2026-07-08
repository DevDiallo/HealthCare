package com.healthcare.hospital.controller;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.HospitalStatus;
import com.healthcare.hospital.service.HospitalService;
import com.healthcare.hospital.util.ApiResponse;
import com.healthcare.hospital.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/hospitals")
public class HospitalController {

    private final HospitalService hospitalService;

    public HospitalController(HospitalService hospitalService) {
        this.hospitalService = hospitalService;
    }

    @PostMapping({"", "/"})
    public ApiResponse<HospitalResponse> create(@Valid @RequestBody HospitalCreateRequest request) {
        return ApiResponse.ok("Hospital created", hospitalService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<HospitalResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Hospital fetched", hospitalService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<HospitalResponse> update(@PathVariable UUID id, @Valid @RequestBody HospitalUpdateRequest request) {
        return ApiResponse.ok("Hospital updated", hospitalService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        hospitalService.delete(id);
        return ApiResponse.ok("Hospital deleted", null);
    }

    @PatchMapping("/{id}/activate")
    public ApiResponse<HospitalResponse> activate(@PathVariable UUID id) {
        return ApiResponse.ok("Hospital activated", hospitalService.activate(id));
    }

    @PatchMapping("/{id}/suspend")
    public ApiResponse<HospitalResponse> suspend(@PathVariable UUID id) {
        return ApiResponse.ok("Hospital suspended", hospitalService.suspend(id));
    }

    @GetMapping({"", "/"})
    public ApiResponse<PageResponse<HospitalResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) HospitalStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Hospitals listed", hospitalService.list(search, status, page, size, sort));
    }
}
