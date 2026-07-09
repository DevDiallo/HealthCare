package com.healthcare.doctor.controller;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.service.DoctorService;
import com.healthcare.doctor.util.ApiResponse;
import com.healthcare.doctor.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    private final DoctorService doctorService;

    public DoctorController(DoctorService doctorService) {
        this.doctorService = doctorService;
    }

    @PostMapping({"", "/"})
    public ApiResponse<DoctorResponse> create(@Valid @RequestBody DoctorCreateRequest request) {
        return ApiResponse.ok("Doctor created", doctorService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<DoctorResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Doctor fetched", doctorService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<DoctorResponse> update(@PathVariable UUID id, @Valid @RequestBody DoctorUpdateRequest request) {
        return ApiResponse.ok("Doctor updated", doctorService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        doctorService.delete(id);
        return ApiResponse.ok("Doctor deleted", null);
    }

    @GetMapping({"", "/"})
    public ApiResponse<PageResponse<DoctorResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String speciality,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Doctors listed", doctorService.list(search, speciality, page, size, sort));
    }

    @GetMapping("/by-user/{userAccountId}")
    public ApiResponse<DoctorResponse> getByUserAccountId(@PathVariable UUID userAccountId) {
        return ApiResponse.ok("Doctor fetched", doctorService.getByUserAccountId(userAccountId));
    }
}
