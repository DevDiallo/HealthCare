package com.healthcare.appointment.service.impl;

import com.healthcare.appointment.dto.AppointmentCreateRequest;
import com.healthcare.appointment.dto.AppointmentResponse;
import com.healthcare.appointment.dto.AppointmentUpdateRequest;
import com.healthcare.appointment.client.DoctorServiceClient;
import com.healthcare.appointment.client.PatientServiceClient;
import com.healthcare.appointment.event.AppointmentEvent;
import com.healthcare.appointment.event.AppointmentEventPublisher;
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
import java.util.Objects;
import java.util.UUID;
import java.time.Instant;

@Service
@Transactional
public class AppointmentServiceImpl implements AppointmentService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "appointmentAt", "status");

    private final AppointmentRepository repository;
    private final AppointmentMapper mapper;
    private final PatientServiceClient patientServiceClient;
    private final DoctorServiceClient doctorServiceClient;
    private final AppointmentEventPublisher eventPublisher;

    public AppointmentServiceImpl(
            AppointmentRepository repository,
            AppointmentMapper mapper,
            PatientServiceClient patientServiceClient,
            DoctorServiceClient doctorServiceClient,
            AppointmentEventPublisher eventPublisher
    ) {
        this.repository = repository;
        this.mapper = mapper;
        this.patientServiceClient = patientServiceClient;
        this.doctorServiceClient = doctorServiceClient;
        this.eventPublisher = eventPublisher;
    }

    @Override
    public AppointmentResponse create(AppointmentCreateRequest request) {
        patientServiceClient.ensurePatientExists(request.patientId());
        doctorServiceClient.ensureDoctorExists(request.doctorId());
        Appointment appointment = mapper.toEntity(request);
        appointment.setHospitalId(resolveHospitalScope(request.hospitalId()));
        Appointment saved = repository.save(appointment);
        publishEvent("APPOINTMENT_CREATED", saved);
        return mapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public AppointmentResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public AppointmentResponse update(UUID id, AppointmentUpdateRequest request) {
        patientServiceClient.ensurePatientExists(request.patientId());
        doctorServiceClient.ensureDoctorExists(request.doctorId());
        Appointment appointment = loadAndAuthorize(id);
        mapper.merge(appointment, request);
        appointment.setHospitalId(resolveHospitalScope(request.hospitalId()));
        Appointment saved = repository.save(appointment);
        publishEvent("APPOINTMENT_UPDATED", saved);
        return mapper.toResponse(saved);
    }

    @Override
    public void delete(UUID id) {
        repository.delete(Objects.requireNonNull(loadAndAuthorize(id)));
    }

    @Override
    public AppointmentResponse confirm(UUID id) {
        Appointment appointment = loadAndAuthorize(id);
        appointment.setStatus(AppointmentStatus.CONFIRMED);
        Appointment saved = repository.save(appointment);
        publishEvent("APPOINTMENT_CONFIRMED", saved);
        return mapper.toResponse(saved);
    }

    @Override
    public AppointmentResponse cancel(UUID id) {
        Appointment appointment = loadAndAuthorize(id);
        appointment.setStatus(AppointmentStatus.CANCELLED);
        Appointment saved = repository.save(appointment);
        publishEvent("APPOINTMENT_CANCELLED", saved);
        return mapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<AppointmentResponse> list(AppointmentStatus status, int page, int size, String sort) {
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Appointment> spec = (root, query, cb) -> cb.conjunction();
        if (hospitalScope != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
        }
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        var pageable = PageRequest.of(page, size, Objects.requireNonNull(SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt")));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Appointment loadAndAuthorize(UUID id) {
        Appointment appointment = repository.findById(Objects.requireNonNull(id)).orElseThrow(() -> new NotFoundException("Appointment not found: " + id));
        UUID scope = resolveHospitalScope(null);
        if (scope != null && !scope.equals(appointment.getHospitalId())) {
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
            return requestedHospitalId;
        }
        if (currentUser.hospitalId() == null) {
            return requestedHospitalId;
        }
        if (requestedHospitalId != null && !requestedHospitalId.equals(currentUser.hospitalId())) {
            throw new UnauthorizedException("Cannot use another hospitalId");
        }
        return currentUser.hospitalId();
    }

    private void publishEvent(String eventType, Appointment appointment) {
        eventPublisher.publish(new AppointmentEvent(
                eventType,
                appointment.getId(),
                appointment.getHospitalId(),
                appointment.getPatientId(),
                appointment.getDoctorId(),
                appointment.getStatus().name(),
                appointment.getAppointmentAt(),
                Instant.now()
        ));
    }
}
