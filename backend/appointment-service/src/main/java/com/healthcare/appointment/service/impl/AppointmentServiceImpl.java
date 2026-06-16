package com.healthcare.appointment.service.impl;

import com.healthcare.appointment.dto.AppointmentCreateRequest;
import com.healthcare.appointment.dto.AppointmentResponse;
import com.healthcare.appointment.dto.AppointmentUpdateRequest;
import com.healthcare.appointment.entity.Appointment;
import com.healthcare.appointment.entity.AppointmentStatus;
import com.healthcare.appointment.exception.NotFoundException;
import com.healthcare.appointment.exception.UnauthorizedException;
import com.healthcare.appointment.mapper.AppointmentMapper;
import com.healthcare.appointment.repository.AppointmentRepository;
import com.healthcare.appointment.security.TenantContextHolder;
import com.healthcare.appointment.security.UserRole;
import com.healthcare.appointment.service.AppointmentService;
import com.healthcare.appointment.util.PageResponse;
import com.healthcare.appointment.util.SortUtils;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class AppointmentServiceImpl implements AppointmentService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "appointmentAt", "status");

    private final AppointmentRepository repository;
    private final AppointmentMapper mapper;

    public AppointmentServiceImpl(AppointmentRepository repository, AppointmentMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public AppointmentResponse create(AppointmentCreateRequest request) {
        Appointment appointment = mapper.toEntity(request);
        appointment.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(appointment));
    }

    @Override
    @Transactional(readOnly = true)
    public AppointmentResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public AppointmentResponse update(UUID id, AppointmentUpdateRequest request) {
        Appointment appointment = loadAndAuthorize(id);
        mapper.merge(appointment, request);
        appointment.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(appointment));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(loadAndAuthorize(id));
    }

    @Override
    public AppointmentResponse confirm(UUID id) {
        Appointment appointment = loadAndAuthorize(id);
        appointment.setStatus(AppointmentStatus.CONFIRMED);
        return mapper.toResponse(repository.save(appointment));
    }

    @Override
    public AppointmentResponse cancel(UUID id) {
        Appointment appointment = loadAndAuthorize(id);
        appointment.setStatus(AppointmentStatus.CANCELLED);
        return mapper.toResponse(repository.save(appointment));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<AppointmentResponse> list(AppointmentStatus status, int page, int size, String sort) {
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Appointment> spec = (root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope);
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        var pageable = PageRequest.of(page, size, SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt"));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Appointment loadAndAuthorize(UUID id) {
        Appointment appointment = repository.findById(id).orElseThrow(() -> new NotFoundException("Appointment not found: " + id));
        UUID scope = resolveHospitalScope(null);
        if (!scope.equals(appointment.getHospitalId())) {
            throw new UnauthorizedException("Access denied for this appointment");
        }
        return appointment;
    }

    private UUID resolveHospitalScope(UUID requestedHospitalId) {
        var currentUser = TenantContextHolder.get();
        if (currentUser == null) {
            throw new UnauthorizedException("Missing authenticated user");
        }
        if (currentUser.role() == UserRole.SUPER_ADMIN) {
            if (requestedHospitalId == null) {
                throw new UnauthorizedException("SUPER_ADMIN must provide hospitalId");
            }
            return requestedHospitalId;
        }
        if (currentUser.hospitalId() == null) {
            throw new UnauthorizedException("Hospital scope missing in token");
        }
        if (requestedHospitalId != null && !requestedHospitalId.equals(currentUser.hospitalId())) {
            throw new UnauthorizedException("Cannot use another hospitalId");
        }
        return currentUser.hospitalId();
    }
}
