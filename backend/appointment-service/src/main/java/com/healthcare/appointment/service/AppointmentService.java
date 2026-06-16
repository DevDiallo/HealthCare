package com.healthcare.appointment.service;

import com.healthcare.appointment.dto.AppointmentCreateRequest;
import com.healthcare.appointment.dto.AppointmentResponse;
import com.healthcare.appointment.dto.AppointmentUpdateRequest;
import com.healthcare.appointment.entity.AppointmentStatus;
import com.healthcare.appointment.util.PageResponse;

import java.util.UUID;

public interface AppointmentService {

    AppointmentResponse create(AppointmentCreateRequest request);

    AppointmentResponse getById(UUID id);

    AppointmentResponse update(UUID id, AppointmentUpdateRequest request);

    void delete(UUID id);

    AppointmentResponse confirm(UUID id);

    AppointmentResponse cancel(UUID id);

    PageResponse<AppointmentResponse> list(AppointmentStatus status, int page, int size, String sort);
}
