package com.healthcare.patient.service.impl;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.client.DoctorServiceClient;
import com.healthcare.patient.entity.Patient;
import com.healthcare.patient.exception.NotFoundException;
import com.healthcare.patient.exception.UnauthorizedException;
import com.healthcare.patient.mapper.PatientMapper;
import com.healthcare.patient.repository.PatientRepository;
import com.healthcare.patient.security.TenantContextHolder;
import com.healthcare.patient.security.UserRole;
import com.healthcare.patient.service.PatientService;
import com.healthcare.patient.util.PageResponse;
import com.healthcare.patient.util.SortUtils;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.Objects;
import java.util.UUID;

@Service
@Transactional
public class PatientServiceImpl implements PatientService {

        private static final Set<String> ALLOWED_SORT = Set.of(
            "createdAt", "updatedAt", "firstName", "lastName", "email", "bloodType", "emergencyContact", "assignedDoctorUserId"
        );

    private final PatientRepository repository;
    private final PatientMapper mapper;
    private final DoctorServiceClient doctorServiceClient;

    public PatientServiceImpl(PatientRepository repository, PatientMapper mapper, DoctorServiceClient doctorServiceClient) {
        this.repository = repository;
        this.mapper = mapper;
        this.doctorServiceClient = doctorServiceClient;
    }

    @Override
    public PatientResponse create(PatientCreateRequest request) {
        if (request.assignedDoctorUserId() != null) {
            doctorServiceClient.ensureDoctorExists(request.assignedDoctorUserId());
        }
        Patient patient = mapper.toEntity(request);
        patient.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(patient));
    }

    @Override
    @Transactional(readOnly = true)
    public PatientResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public PatientResponse update(UUID id, PatientUpdateRequest request) {
        if (request.assignedDoctorUserId() != null) {
            doctorServiceClient.ensureDoctorExists(request.assignedDoctorUserId());
        }
        Patient patient = loadAndAuthorize(id);
        mapper.merge(patient, request);
        patient.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(patient));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(Objects.requireNonNull(loadAndAuthorize(id)));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<PatientResponse> list(String search, int page, int size, String sort) {
        var currentUser = requireCurrentUser();
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Patient> spec = (root, query, cb) -> cb.conjunction();
        if (hospitalScope != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
        }
        if (currentUser.role() == UserRole.DOCTOR) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("assignedDoctorUserId"), currentUser.userId()));
        }
        if (currentUser.role() == UserRole.PATIENT) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("userAccountId"), currentUser.userId()));
        }
        if (search != null && !search.isBlank()) {
            String pattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.get("firstName")), pattern),
                    cb.like(cb.lower(root.get("lastName")), pattern),
                    cb.like(cb.lower(root.get("email")), pattern),
                    cb.like(cb.lower(root.get("bloodType")), pattern),
                    cb.like(cb.lower(root.get("allergies")), pattern),
                    cb.like(cb.lower(root.get("chronicConditions")), pattern),
                    cb.like(cb.lower(root.get("emergencyContact")), pattern)
            ));
        }
        var pageable = PageRequest.of(page, size, Objects.requireNonNull(SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt")));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Patient loadAndAuthorize(UUID id) {
        Patient patient = repository.findById(Objects.requireNonNull(id)).orElseThrow(() -> new NotFoundException("Patient not found: " + id));
        var currentUser = requireCurrentUser();
        if (currentUser.role() == UserRole.DOCTOR && !currentUser.userId().equals(patient.getAssignedDoctorUserId())) {
            throw new UnauthorizedException("Access denied for this patient");
        }
        if (currentUser.role() == UserRole.PATIENT && !currentUser.userId().equals(patient.getUserAccountId())) {
            throw new UnauthorizedException("Access denied for this patient");
        }
        UUID scope = resolveHospitalScope(null);
        if (scope != null && !scope.equals(patient.getHospitalId())) {
            throw new UnauthorizedException("Access denied for this patient");
        }
        return patient;
    }

    private com.healthcare.patient.security.CurrentUser requireCurrentUser() {
        var currentUser = TenantContextHolder.get();
        if (currentUser == null) {
            throw new UnauthorizedException("Missing authenticated user");
        }
        return currentUser;
    }

    private UUID resolveHospitalScope(UUID requestedHospitalId) {
        var currentUser = requireCurrentUser();
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
}
