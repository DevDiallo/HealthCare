package com.healthcare.notification.service.impl;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.entity.Notification;
import com.healthcare.notification.entity.NotificationStatus;
import com.healthcare.notification.exception.NotFoundException;
import com.healthcare.notification.exception.UnauthorizedException;
import com.healthcare.notification.mapper.NotificationMapper;
import com.healthcare.notification.repository.NotificationRepository;
import com.healthcare.notification.security.TenantContextHolder;
import com.healthcare.notification.security.UserRole;
import com.healthcare.notification.service.NotificationService;
import com.healthcare.notification.util.PageResponse;
import com.healthcare.notification.util.SortUtils;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "status", "title");

    private final NotificationRepository repository;
    private final NotificationMapper mapper;

    public NotificationServiceImpl(NotificationRepository repository, NotificationMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public NotificationResponse create(NotificationCreateRequest request) {
        Notification notification = mapper.toEntity(request);
        notification.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(notification));
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationResponse getById(UUID id) {
        return mapper.toResponse(loadAndAuthorize(id));
    }

    @Override
    public NotificationResponse update(UUID id, NotificationUpdateRequest request) {
        Notification notification = loadAndAuthorize(id);
        mapper.merge(notification, request);
        notification.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(notification));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(loadAndAuthorize(id));
    }

    @Override
    public NotificationResponse send(UUID id) {
        Notification notification = loadAndAuthorize(id);
        notification.setStatus(NotificationStatus.SENT);
        notification.setSentAt(Instant.now());
        return mapper.toResponse(repository.save(notification));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> list(int page, int size, String sort) {
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Notification> spec = (root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope);
        var pageable = PageRequest.of(page, size, SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt"));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Notification loadAndAuthorize(UUID id) {
        Notification notification = repository.findById(id).orElseThrow(() -> new NotFoundException("Notification not found: " + id));
        UUID scope = resolveHospitalScope(null);
        if (!scope.equals(notification.getHospitalId())) {
            throw new UnauthorizedException("Access denied for this notification");
        }
        return notification;
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
