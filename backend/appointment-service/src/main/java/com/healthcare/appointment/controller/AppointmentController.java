package com.healthcare.appointment.controller;

import com.healthcare.appointment.dto.AppointmentCreateRequest;
import com.healthcare.appointment.dto.AppointmentResponse;
import com.healthcare.appointment.dto.AppointmentUpdateRequest;
import com.healthcare.appointment.entity.AppointmentStatus;
import com.healthcare.appointment.service.AppointmentService;
import com.healthcare.appointment.util.ApiResponse;
import com.healthcare.appointment.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;

    public AppointmentController(AppointmentService appointmentService) {
        this.appointmentService = appointmentService;
    }

    @PostMapping({"", "/"})
    public ApiResponse<AppointmentResponse> create(@Valid @RequestBody AppointmentCreateRequest request) {
        return ApiResponse.ok("Appointment created", appointmentService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<AppointmentResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Appointment fetched", appointmentService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<AppointmentResponse> update(@PathVariable UUID id, @Valid @RequestBody AppointmentUpdateRequest request) {
        return ApiResponse.ok("Appointment updated", appointmentService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        appointmentService.delete(id);
        return ApiResponse.ok("Appointment deleted", null);
    }

    @PatchMapping("/{id}/confirm")
    public ApiResponse<AppointmentResponse> confirm(@PathVariable UUID id) {
        return ApiResponse.ok("Appointment confirmed", appointmentService.confirm(id));
    }

    @PatchMapping("/{id}/cancel")
    public ApiResponse<AppointmentResponse> cancel(@PathVariable UUID id) {
        return ApiResponse.ok("Appointment cancelled", appointmentService.cancel(id));
    }

    @GetMapping({"", "/"})
    public ApiResponse<PageResponse<AppointmentResponse>> list(
            @RequestParam(required = false) AppointmentStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Appointments listed", appointmentService.list(status, page, size, sort));
    }
}
