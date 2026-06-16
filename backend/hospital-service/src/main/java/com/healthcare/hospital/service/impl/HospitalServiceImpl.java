package com.healthcare.hospital.service.impl;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.Hospital;
import com.healthcare.hospital.entity.HospitalStatus;
import com.healthcare.hospital.exception.NotFoundException;
import com.healthcare.hospital.exception.UnauthorizedException;
import com.healthcare.hospital.mapper.HospitalMapper;
import com.healthcare.hospital.repository.HospitalRepository;
import com.healthcare.hospital.security.TenantContextHolder;
import com.healthcare.hospital.security.UserRole;
import com.healthcare.hospital.service.HospitalService;
import com.healthcare.hospital.util.PageResponse;
import com.healthcare.hospital.util.SortUtils;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class HospitalServiceImpl implements HospitalService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "name", "status");

    private final HospitalRepository repository;
    private final HospitalMapper mapper;

    public HospitalServiceImpl(HospitalRepository repository, HospitalMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public HospitalResponse create(HospitalCreateRequest request) {
        requireSuperAdmin();
        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    @Override
    @Transactional(readOnly = true)
    public HospitalResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public HospitalResponse update(UUID id, HospitalUpdateRequest request) {
        Hospital hospital = loadAndAuthorize(id);
        mapper.merge(hospital, request);
        return mapper.toResponse(repository.save(hospital));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(loadAndAuthorize(id));
    }

    @Override
    public HospitalResponse activate(UUID id) {
        Hospital hospital = loadAndAuthorize(id);
        hospital.setStatus(HospitalStatus.ACTIVE);
        return mapper.toResponse(repository.save(hospital));
    }

    @Override
    public HospitalResponse suspend(UUID id) {
        Hospital hospital = loadAndAuthorize(id);
        hospital.setStatus(HospitalStatus.SUSPENDED);
        return mapper.toResponse(repository.save(hospital));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<HospitalResponse> list(String search, HospitalStatus status, int page, int size, String sort) {
        UUID scopedHospital = hospitalScope();
        Specification<Hospital> spec = (root, query, cb) -> cb.conjunction();

        if (search != null && !search.isBlank()) {
            String pattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.get("name")), pattern),
                    cb.like(cb.lower(root.get("address")), pattern)
            ));
        }
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        if (scopedHospital != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("id"), scopedHospital));
        }

        var pageable = PageRequest.of(page, size, SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt"));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Hospital loadAndAuthorize(UUID id) {
        Hospital hospital = repository.findById(id).orElseThrow(() -> new NotFoundException("Hospital not found: " + id));
        UUID scopedHospital = hospitalScope();
        if (scopedHospital != null && !scopedHospital.equals(hospital.getId())) {
            throw new UnauthorizedException("Access denied for this hospital");
        }
        return hospital;
    }

    private UUID hospitalScope() {
        var user = TenantContextHolder.get();
        if (user == null) {
            throw new UnauthorizedException("Missing authenticated user");
        }
        if (user.role() == UserRole.SUPER_ADMIN) {
            return null;
        }
        if (user.hospitalId() == null) {
            throw new UnauthorizedException("Hospital scope missing in token");
        }
        return user.hospitalId();
    }

    private void requireSuperAdmin() {
        var user = TenantContextHolder.get();
        if (user == null || user.role() != UserRole.SUPER_ADMIN) {
            throw new UnauthorizedException("Only SUPER_ADMIN can create hospitals");
        }
    }
}
