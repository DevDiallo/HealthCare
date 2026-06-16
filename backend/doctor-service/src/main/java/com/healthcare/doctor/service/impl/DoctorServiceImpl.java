package com.healthcare.doctor.service.impl;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.entity.Doctor;
import com.healthcare.doctor.exception.NotFoundException;
import com.healthcare.doctor.exception.UnauthorizedException;
import com.healthcare.doctor.mapper.DoctorMapper;
import com.healthcare.doctor.repository.DoctorRepository;
import com.healthcare.doctor.security.TenantContextHolder;
import com.healthcare.doctor.security.UserRole;
import com.healthcare.doctor.service.DoctorService;
import com.healthcare.doctor.util.PageResponse;
import com.healthcare.doctor.util.SortUtils;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class DoctorServiceImpl implements DoctorService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "firstName", "lastName", "speciality");

    private final DoctorRepository repository;
    private final DoctorMapper mapper;

    public DoctorServiceImpl(DoctorRepository repository, DoctorMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public DoctorResponse create(DoctorCreateRequest request) {
        Doctor doctor = mapper.toEntity(request);
        doctor.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(doctor));
    }

    @Override
    @Transactional(readOnly = true)
    public DoctorResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public DoctorResponse update(UUID id, DoctorUpdateRequest request) {
        Doctor doctor = loadAndAuthorize(id);
        mapper.merge(doctor, request);
        doctor.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(doctor));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(loadAndAuthorize(id));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<DoctorResponse> list(String search, String speciality, int page, int size, String sort) {
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Doctor> spec = (root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope);
        if (search != null && !search.isBlank()) {
            String pattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.get("firstName")), pattern),
                    cb.like(cb.lower(root.get("lastName")), pattern)
            ));
        }
        if (speciality != null && !speciality.isBlank()) {
            String specialityVal = speciality.toLowerCase();
            spec = spec.and((root, query, cb) -> cb.equal(cb.lower(root.get("speciality")), specialityVal));
        }
        var pageable = PageRequest.of(page, size, SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt"));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Doctor loadAndAuthorize(UUID id) {
        Doctor doctor = repository.findById(id).orElseThrow(() -> new NotFoundException("Doctor not found: " + id));
        UUID scope = resolveHospitalScope(null);
        if (!scope.equals(doctor.getHospitalId())) {
            throw new UnauthorizedException("Access denied for this doctor");
        }
        return doctor;
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
