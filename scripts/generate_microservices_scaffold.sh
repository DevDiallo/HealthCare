#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/diallo/Documents/ISOSET/HealthCare/backend"

reset_service() {
  local service="$1"
  rm -rf "$ROOT/$service/src"
  rm -f "$ROOT/$service/pom.xml" "$ROOT/$service/Dockerfile"
  mkdir -p "$ROOT/$service/src/main/java" "$ROOT/$service/src/main/resources" "$ROOT/$service/src/test/java" "$ROOT/$service/src/test/resources"
}

write_common() {
  local service="$1"
  local pkg="$2"
  local app_class="$3"
  local artifact="$4"
  local app_name="$5"

  local base="$ROOT/$service/src/main/java/com/healthcare/$pkg"
  mkdir -p "$base" "$base/config" "$base/security" "$base/exception" "$base/util" "$base/dto" "$base/entity" "$base/repository" "$base/mapper" "$base/service/impl" "$base/controller"
  mkdir -p "$ROOT/$service/src/test/java/com/healthcare/$pkg"

  cat > "$ROOT/$service/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.0</version>
        <relativePath/>
    </parent>

    <groupId>com.healthcare</groupId>
    <artifactId>$artifact</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>$app_name</name>
    <description>$app_name microservice</description>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.release>21</maven.compiler.release>
        <jjwt.version>0.12.6</jjwt.version>
        <springdoc.version>2.8.0</springdoc.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>\${springdoc.version}</version>
        </dependency>

        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>\${jjwt.version}</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>\${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>\${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

  cat > "$ROOT/$service/Dockerfile" <<EOF
FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
EOF

  cat > "$ROOT/$service/src/main/resources/application.yml" <<EOF
spring:
  application:
    name: $service
  datasource:
    url: \${DB_URL:jdbc:postgresql://localhost:5432/healthcare}
    username: \${DB_USERNAME:healthcare}
    password: \${DB_PASSWORD:healthcare}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

server:
  port: \${SERVER_PORT:8080}

app:
  jwt-secret: \${JWT_SECRET:0123456789ABCDEF0123456789ABCDEF}
  jwt-expiration-seconds: \${JWT_EXPIRATION_SECONDS:3600}
EOF

  cat > "$ROOT/$service/src/test/resources/application-test.yml" <<EOF
spring:
  datasource:
    url: jdbc:h2:mem:${pkg}db;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: sa
    password:
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop

app:
  jwt-secret: test-secret-key-test-secret-key-1234
  jwt-expiration-seconds: 3600
EOF

  cat > "$base/$app_class.java" <<EOF
package com.healthcare.$pkg;

import com.healthcare.$pkg.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(AppProperties.class)
public class $app_class {

    public static void main(String[] args) {
        SpringApplication.run($app_class.class, args);
    }
}
EOF

  cat > "$base/config/AppProperties.java" <<EOF
package com.healthcare.$pkg.config;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    @NotBlank
    private String jwtSecret;

    @Positive
    private long jwtExpirationSeconds = 3600;

    public String getJwtSecret() {
        return jwtSecret;
    }

    public void setJwtSecret(String jwtSecret) {
        this.jwtSecret = jwtSecret;
    }

    public long getJwtExpirationSeconds() {
        return jwtExpirationSeconds;
    }

    public void setJwtExpirationSeconds(long jwtExpirationSeconds) {
        this.jwtExpirationSeconds = jwtExpirationSeconds;
    }
}
EOF

  cat > "$base/config/OpenApiConfig.java" <<EOF
package com.healthcare.$pkg.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI().info(new Info().title("$app_name API").version("v1"));
    }
}
EOF

  cat > "$base/security/UserRole.java" <<EOF
package com.healthcare.$pkg.security;

public enum UserRole {
    SUPER_ADMIN,
    HOSPITAL_ADMIN,
    DOCTOR,
    PATIENT,
    SYSTEM
}
EOF

  cat > "$base/security/CurrentUser.java" <<EOF
package com.healthcare.$pkg.security;

import java.util.UUID;

public record CurrentUser(UUID userId, UUID hospitalId, UserRole role) {
}
EOF

  cat > "$base/security/TenantContextHolder.java" <<EOF
package com.healthcare.$pkg.security;

public final class TenantContextHolder {

    private static final ThreadLocal<CurrentUser> HOLDER = new ThreadLocal<>();

    private TenantContextHolder() {
    }

    public static void set(CurrentUser currentUser) {
        HOLDER.set(currentUser);
    }

    public static CurrentUser get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }
}
EOF

  cat > "$base/security/JwtService.java" <<EOF
package com.healthcare.$pkg.security;

import com.healthcare.$pkg.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Service
public class JwtService {

    private final SecretKey secretKey;

    public JwtService(AppProperties appProperties) {
        this.secretKey = Keys.hmacShaKeyFor(appProperties.getJwtSecret().getBytes(StandardCharsets.UTF_8));
    }

    public CurrentUser parse(String token) {
        Claims claims = Jwts.parser().verifyWith(secretKey).build().parseSignedClaims(token).getPayload();
        String roleRaw = claims.get("role", String.class);
        String hospitalRaw = claims.get("hospitalId", String.class);
        return new CurrentUser(
                UUID.fromString(claims.get("userId", String.class)),
                hospitalRaw == null || hospitalRaw.isBlank() ? null : UUID.fromString(hospitalRaw),
                roleRaw == null ? UserRole.PATIENT : UserRole.valueOf(roleRaw)
        );
    }
}
EOF

  cat > "$base/security/JwtAuthenticationFilter.java" <<EOF
package com.healthcare.$pkg.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String auth = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (auth != null && auth.startsWith("Bearer ")) {
            try {
                CurrentUser currentUser = jwtService.parse(auth.substring(7));
                request.setAttribute(CurrentUser.class.getName(), currentUser);
                var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + currentUser.role().name()));
                var authentication = new UsernamePasswordAuthenticationToken(currentUser, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (RuntimeException ex) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}
EOF

  cat > "$base/security/TenantContextFilter.java" <<EOF
package com.healthcare.$pkg.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class TenantContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            Object principal = SecurityContextHolder.getContext().getAuthentication() == null
                    ? null
                    : SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (principal instanceof CurrentUser currentUser) {
                TenantContextHolder.set(currentUser);
            } else {
                Object fromRequest = request.getAttribute(CurrentUser.class.getName());
                if (fromRequest instanceof CurrentUser currentUser) {
                    TenantContextHolder.set(currentUser);
                }
            }
            filterChain.doFilter(request, response);
        } finally {
            TenantContextHolder.clear();
        }
    }
}
EOF

  cat > "$base/security/SecurityConfig.java" <<EOF
package com.healthcare.$pkg.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   JwtAuthenticationFilter jwtAuthenticationFilter,
                                                   TenantContextFilter tenantContextFilter) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html", "/actuator/health").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(tenantContextFilter, JwtAuthenticationFilter.class)
                .build();
    }
}
EOF

  cat > "$base/exception/ApiErrorResponse.java" <<EOF
package com.healthcare.$pkg.exception;

import java.time.Instant;
import java.util.List;

public record ApiErrorResponse(Instant timestamp, int status, String error, String message, List<String> details) {
}
EOF

  cat > "$base/exception/BusinessException.java" <<EOF
package com.healthcare.$pkg.exception;

public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
EOF

  cat > "$base/exception/NotFoundException.java" <<EOF
package com.healthcare.$pkg.exception;

public class NotFoundException extends RuntimeException {

    public NotFoundException(String message) {
        super(message);
    }
}
EOF

  cat > "$base/exception/UnauthorizedException.java" <<EOF
package com.healthcare.$pkg.exception;

public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
EOF

  cat > "$base/exception/GlobalExceptionHandler.java" <<EOF
package com.healthcare.$pkg.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNotFound(NotFoundException ex) {
        return error(HttpStatus.NOT_FOUND, ex.getMessage(), List.of());
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<ApiErrorResponse> handleUnauthorized(UnauthorizedException ex) {
        return error(HttpStatus.FORBIDDEN, ex.getMessage(), List.of());
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiErrorResponse> handleBusiness(BusinessException ex) {
        return error(HttpStatus.BAD_REQUEST, ex.getMessage(), List.of());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fieldError -> fieldError.getField() + ": " + fieldError.getDefaultMessage())
                .toList();
        return error(HttpStatus.BAD_REQUEST, "Validation failed", details);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleUnexpected(Exception ex) {
        return error(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error", List.of(ex.getMessage()));
    }

    private ResponseEntity<ApiErrorResponse> error(HttpStatus status, String message, List<String> details) {
        return ResponseEntity.status(status)
                .body(new ApiErrorResponse(Instant.now(), status.value(), status.getReasonPhrase(), message, details));
    }
}
EOF

  cat > "$base/util/ApiResponse.java" <<EOF
package com.healthcare.$pkg.util;

import java.time.Instant;

public record ApiResponse<T>(boolean success, String message, T data, Instant timestamp) {

    public static <T> ApiResponse<T> ok(String message, T data) {
        return new ApiResponse<>(true, message, data, Instant.now());
    }
}
EOF

  cat > "$base/util/PageResponse.java" <<EOF
package com.healthcare.$pkg.util;

import org.springframework.data.domain.Page;

import java.util.List;

public record PageResponse<T>(List<T> items, int page, int size, long totalElements, int totalPages) {

    public static <T> PageResponse<T> from(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages()
        );
    }
}
EOF

  cat > "$base/util/SortUtils.java" <<EOF
package com.healthcare.$pkg.util;

import org.springframework.data.domain.Sort;

import java.util.Set;

public final class SortUtils {

    private SortUtils() {
    }

    public static Sort parseSort(String sort, Set<String> allowed, String fallback) {
        if (sort == null || sort.isBlank()) {
            return Sort.by(Sort.Direction.DESC, fallback);
        }
        String[] parts = sort.split(",");
        String field = allowed.contains(parts[0]) ? parts[0] : fallback;
        Sort.Direction dir = parts.length > 1 && "asc".equalsIgnoreCase(parts[1])
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;
        return Sort.by(dir, field);
    }
}
EOF

  cat > "$ROOT/$service/src/test/java/com/healthcare/$pkg/${app_class}Tests.java" <<EOF
package com.healthcare.$pkg;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class ${app_class}Tests {

    @Test
    void contextLoads() {
    }
}
EOF
}

write_hospital() {
  local base="$ROOT/hospital-service/src/main/java/com/healthcare/hospital"

  cat > "$base/entity/HospitalStatus.java" <<EOF
package com.healthcare.hospital.entity;

public enum HospitalStatus {
    ACTIVE,
    SUSPENDED
}
EOF

  cat > "$base/entity/Hospital.java" <<EOF
package com.healthcare.hospital.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hospitals")
public class Hospital {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String address;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private HospitalStatus status = HospitalStatus.ACTIVE;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public HospitalStatus getStatus() { return status; }
    public void setStatus(HospitalStatus status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
EOF

  cat > "$base/dto/HospitalCreateRequest.java" <<EOF
package com.healthcare.hospital.dto;

import jakarta.validation.constraints.NotBlank;

public record HospitalCreateRequest(
        @NotBlank(message = "name is required") String name,
        @NotBlank(message = "address is required") String address
) {
}
EOF

  cat > "$base/dto/HospitalUpdateRequest.java" <<EOF
package com.healthcare.hospital.dto;

import jakarta.validation.constraints.NotBlank;

public record HospitalUpdateRequest(
        @NotBlank(message = "name is required") String name,
        @NotBlank(message = "address is required") String address
) {
}
EOF

  cat > "$base/dto/HospitalResponse.java" <<EOF
package com.healthcare.hospital.dto;

import com.healthcare.hospital.entity.HospitalStatus;

import java.time.Instant;
import java.util.UUID;

public record HospitalResponse(
        UUID id,
        String name,
        String address,
        HospitalStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
EOF

  cat > "$base/repository/HospitalRepository.java" <<EOF
package com.healthcare.hospital.repository;

import com.healthcare.hospital.entity.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface HospitalRepository extends JpaRepository<Hospital, UUID>, JpaSpecificationExecutor<Hospital> {
}
EOF

  cat > "$base/mapper/HospitalMapper.java" <<EOF
package com.healthcare.hospital.mapper;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.Hospital;
import org.springframework.stereotype.Component;

@Component
public class HospitalMapper {

    public Hospital toEntity(HospitalCreateRequest request) {
        Hospital hospital = new Hospital();
        hospital.setName(request.name());
        hospital.setAddress(request.address());
        return hospital;
    }

    public void merge(Hospital hospital, HospitalUpdateRequest request) {
        hospital.setName(request.name());
        hospital.setAddress(request.address());
    }

    public HospitalResponse toResponse(Hospital hospital) {
        return new HospitalResponse(
                hospital.getId(),
                hospital.getName(),
                hospital.getAddress(),
                hospital.getStatus(),
                hospital.getCreatedAt(),
                hospital.getUpdatedAt()
        );
    }
}
EOF

  cat > "$base/service/HospitalService.java" <<EOF
package com.healthcare.hospital.service;

import com.healthcare.hospital.dto.HospitalCreateRequest;
import com.healthcare.hospital.dto.HospitalResponse;
import com.healthcare.hospital.dto.HospitalUpdateRequest;
import com.healthcare.hospital.entity.HospitalStatus;
import com.healthcare.hospital.util.PageResponse;

import java.util.UUID;

public interface HospitalService {

    HospitalResponse create(HospitalCreateRequest request);

    HospitalResponse getById(UUID id);

    HospitalResponse update(UUID id, HospitalUpdateRequest request);

    void delete(UUID id);

    HospitalResponse activate(UUID id);

    HospitalResponse suspend(UUID id);

    PageResponse<HospitalResponse> list(String search, HospitalStatus status, int page, int size, String sort);
}
EOF

  cat > "$base/service/impl/HospitalServiceImpl.java" <<EOF
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
        Specification<Hospital> spec = Specification.where(null);

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
EOF

  cat > "$base/controller/HospitalController.java" <<EOF
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

    @PostMapping
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

    @GetMapping
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
EOF
}

write_patient() {
  local base="$ROOT/patient-service/src/main/java/com/healthcare/patient"

  cat > "$base/entity/Patient.java" <<EOF
package com.healthcare.patient.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "patients")
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID hospitalId;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Column(nullable = false)
    private String email;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getHospitalId() { return hospitalId; }
    public void setHospitalId(UUID hospitalId) { this.hospitalId = hospitalId; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
EOF

  cat > "$base/dto/PatientCreateRequest.java" <<EOF
package com.healthcare.patient.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record PatientCreateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @Email(message = "email is invalid") @NotBlank(message = "email is required") String email
) {
}
EOF

  cat > "$base/dto/PatientUpdateRequest.java" <<EOF
package com.healthcare.patient.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record PatientUpdateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @Email(message = "email is invalid") @NotBlank(message = "email is required") String email
) {
}
EOF

  cat > "$base/dto/PatientResponse.java" <<EOF
package com.healthcare.patient.dto;

import java.time.Instant;
import java.util.UUID;

public record PatientResponse(
        UUID id,
        UUID hospitalId,
        String firstName,
        String lastName,
        String email,
        Instant createdAt,
        Instant updatedAt
) {
}
EOF

  cat > "$base/repository/PatientRepository.java" <<EOF
package com.healthcare.patient.repository;

import com.healthcare.patient.entity.Patient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface PatientRepository extends JpaRepository<Patient, UUID>, JpaSpecificationExecutor<Patient> {
}
EOF

  cat > "$base/mapper/PatientMapper.java" <<EOF
package com.healthcare.patient.mapper;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.entity.Patient;
import org.springframework.stereotype.Component;

@Component
public class PatientMapper {

    public Patient toEntity(PatientCreateRequest request) {
        Patient patient = new Patient();
        patient.setFirstName(request.firstName());
        patient.setLastName(request.lastName());
        patient.setEmail(request.email());
        return patient;
    }

    public void merge(Patient patient, PatientUpdateRequest request) {
        patient.setFirstName(request.firstName());
        patient.setLastName(request.lastName());
        patient.setEmail(request.email());
    }

    public PatientResponse toResponse(Patient patient) {
        return new PatientResponse(
                patient.getId(),
                patient.getHospitalId(),
                patient.getFirstName(),
                patient.getLastName(),
                patient.getEmail(),
                patient.getCreatedAt(),
                patient.getUpdatedAt()
        );
    }
}
EOF

  cat > "$base/service/PatientService.java" <<EOF
package com.healthcare.patient.service;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.util.PageResponse;

import java.util.UUID;

public interface PatientService {

    PatientResponse create(PatientCreateRequest request);

    PatientResponse getById(UUID id);

    PatientResponse update(UUID id, PatientUpdateRequest request);

    void delete(UUID id);

    PageResponse<PatientResponse> list(String search, int page, int size, String sort);
}
EOF

  cat > "$base/service/impl/PatientServiceImpl.java" <<EOF
package com.healthcare.patient.service.impl;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
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
import java.util.UUID;

@Service
@Transactional
public class PatientServiceImpl implements PatientService {

    private static final Set<String> ALLOWED_SORT = Set.of("createdAt", "updatedAt", "firstName", "lastName", "email");

    private final PatientRepository repository;
    private final PatientMapper mapper;

    public PatientServiceImpl(PatientRepository repository, PatientMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public PatientResponse create(PatientCreateRequest request) {
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
        Patient patient = loadAndAuthorize(id);
        mapper.merge(patient, request);
        patient.setHospitalId(resolveHospitalScope(request.hospitalId()));
        return mapper.toResponse(repository.save(patient));
    }

    @Override
    public void delete(UUID id) {
        repository.delete(loadAndAuthorize(id));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<PatientResponse> list(String search, int page, int size, String sort) {
        UUID hospitalScope = resolveHospitalScope(null);
        Specification<Patient> spec = Specification.where((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
        if (search != null && !search.isBlank()) {
            String pattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.get("firstName")), pattern),
                    cb.like(cb.lower(root.get("lastName")), pattern),
                    cb.like(cb.lower(root.get("email")), pattern)
            ));
        }
        var pageable = PageRequest.of(page, size, SortUtils.parseSort(sort, ALLOWED_SORT, "createdAt"));
        return PageResponse.from(repository.findAll(spec, pageable).map(mapper::toResponse));
    }

    private Patient loadAndAuthorize(UUID id) {
        Patient patient = repository.findById(id).orElseThrow(() -> new NotFoundException("Patient not found: " + id));
        UUID scope = resolveHospitalScope(null);
        if (!scope.equals(patient.getHospitalId())) {
            throw new UnauthorizedException("Access denied for this patient");
        }
        return patient;
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
EOF

  cat > "$base/controller/PatientController.java" <<EOF
package com.healthcare.patient.controller;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.service.PatientService;
import com.healthcare.patient.util.ApiResponse;
import com.healthcare.patient.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;

    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    @PostMapping
    public ApiResponse<PatientResponse> create(@Valid @RequestBody PatientCreateRequest request) {
        return ApiResponse.ok("Patient created", patientService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<PatientResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Patient fetched", patientService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<PatientResponse> update(@PathVariable UUID id, @Valid @RequestBody PatientUpdateRequest request) {
        return ApiResponse.ok("Patient updated", patientService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        patientService.delete(id);
        return ApiResponse.ok("Patient deleted", null);
    }

    @GetMapping
    public ApiResponse<PageResponse<PatientResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Patients listed", patientService.list(search, page, size, sort));
    }
}
EOF
}

write_doctor() {
  local base="$ROOT/doctor-service/src/main/java/com/healthcare/doctor"

  cat > "$base/entity/Doctor.java" <<EOF
package com.healthcare.doctor.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "doctors")
public class Doctor {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID hospitalId;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Column(nullable = false)
    private String speciality;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getHospitalId() { return hospitalId; }
    public void setHospitalId(UUID hospitalId) { this.hospitalId = hospitalId; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getSpeciality() { return speciality; }
    public void setSpeciality(String speciality) { this.speciality = speciality; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
EOF

  cat > "$base/dto/DoctorCreateRequest.java" <<EOF
package com.healthcare.doctor.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record DoctorCreateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @NotBlank(message = "speciality is required") String speciality
) {
}
EOF

  cat > "$base/dto/DoctorUpdateRequest.java" <<EOF
package com.healthcare.doctor.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record DoctorUpdateRequest(
        UUID hospitalId,
        @NotBlank(message = "firstName is required") String firstName,
        @NotBlank(message = "lastName is required") String lastName,
        @NotBlank(message = "speciality is required") String speciality
) {
}
EOF

  cat > "$base/dto/DoctorResponse.java" <<EOF
package com.healthcare.doctor.dto;

import java.time.Instant;
import java.util.UUID;

public record DoctorResponse(
        UUID id,
        UUID hospitalId,
        String firstName,
        String lastName,
        String speciality,
        Instant createdAt,
        Instant updatedAt
) {
}
EOF

  cat > "$base/repository/DoctorRepository.java" <<EOF
package com.healthcare.doctor.repository;

import com.healthcare.doctor.entity.Doctor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface DoctorRepository extends JpaRepository<Doctor, UUID>, JpaSpecificationExecutor<Doctor> {
}
EOF

  cat > "$base/mapper/DoctorMapper.java" <<EOF
package com.healthcare.doctor.mapper;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.entity.Doctor;
import org.springframework.stereotype.Component;

@Component
public class DoctorMapper {

    public Doctor toEntity(DoctorCreateRequest request) {
        Doctor doctor = new Doctor();
        doctor.setFirstName(request.firstName());
        doctor.setLastName(request.lastName());
        doctor.setSpeciality(request.speciality());
        return doctor;
    }

    public void merge(Doctor doctor, DoctorUpdateRequest request) {
        doctor.setFirstName(request.firstName());
        doctor.setLastName(request.lastName());
        doctor.setSpeciality(request.speciality());
    }

    public DoctorResponse toResponse(Doctor doctor) {
        return new DoctorResponse(
                doctor.getId(),
                doctor.getHospitalId(),
                doctor.getFirstName(),
                doctor.getLastName(),
                doctor.getSpeciality(),
                doctor.getCreatedAt(),
                doctor.getUpdatedAt()
        );
    }
}
EOF

  cat > "$base/service/DoctorService.java" <<EOF
package com.healthcare.doctor.service;

import com.healthcare.doctor.dto.DoctorCreateRequest;
import com.healthcare.doctor.dto.DoctorResponse;
import com.healthcare.doctor.dto.DoctorUpdateRequest;
import com.healthcare.doctor.util.PageResponse;

import java.util.UUID;

public interface DoctorService {

    DoctorResponse create(DoctorCreateRequest request);

    DoctorResponse getById(UUID id);

    DoctorResponse update(UUID id, DoctorUpdateRequest request);

    void delete(UUID id);

    PageResponse<DoctorResponse> list(String search, String speciality, int page, int size, String sort);
}
EOF

  cat > "$base/service/impl/DoctorServiceImpl.java" <<EOF
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
        Specification<Doctor> spec = Specification.where((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
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
EOF

  cat > "$base/controller/DoctorController.java" <<EOF
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

    @PostMapping
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

    @GetMapping
    public ApiResponse<PageResponse<DoctorResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String speciality,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Doctors listed", doctorService.list(search, speciality, page, size, sort));
    }
}
EOF
}

write_appointment() {
  local base="$ROOT/appointment-service/src/main/java/com/healthcare/appointment"

  cat > "$base/entity/AppointmentStatus.java" <<EOF
package com.healthcare.appointment.entity;

public enum AppointmentStatus {
    PENDING,
    CONFIRMED,
    CANCELLED
}
EOF

  cat > "$base/entity/Appointment.java" <<EOF
package com.healthcare.appointment.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "appointments")
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID hospitalId;

    @Column(nullable = false)
    private UUID patientId;

    @Column(nullable = false)
    private UUID doctorId;

    @Column(nullable = false)
    private LocalDateTime appointmentAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AppointmentStatus status = AppointmentStatus.PENDING;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getHospitalId() { return hospitalId; }
    public void setHospitalId(UUID hospitalId) { this.hospitalId = hospitalId; }
    public UUID getPatientId() { return patientId; }
    public void setPatientId(UUID patientId) { this.patientId = patientId; }
    public UUID getDoctorId() { return doctorId; }
    public void setDoctorId(UUID doctorId) { this.doctorId = doctorId; }
    public LocalDateTime getAppointmentAt() { return appointmentAt; }
    public void setAppointmentAt(LocalDateTime appointmentAt) { this.appointmentAt = appointmentAt; }
    public AppointmentStatus getStatus() { return status; }
    public void setStatus(AppointmentStatus status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
EOF

  cat > "$base/dto/AppointmentCreateRequest.java" <<EOF
package com.healthcare.appointment.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentCreateRequest(
        UUID hospitalId,
        @NotNull(message = "patientId is required") UUID patientId,
        @NotNull(message = "doctorId is required") UUID doctorId,
        @NotNull(message = "appointmentAt is required") @Future(message = "appointmentAt must be future") LocalDateTime appointmentAt
) {
}
EOF

  cat > "$base/dto/AppointmentUpdateRequest.java" <<EOF
package com.healthcare.appointment.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentUpdateRequest(
        UUID hospitalId,
        @NotNull(message = "patientId is required") UUID patientId,
        @NotNull(message = "doctorId is required") UUID doctorId,
        @NotNull(message = "appointmentAt is required") @Future(message = "appointmentAt must be future") LocalDateTime appointmentAt
) {
}
EOF

  cat > "$base/dto/AppointmentResponse.java" <<EOF
package com.healthcare.appointment.dto;

import com.healthcare.appointment.entity.AppointmentStatus;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record AppointmentResponse(
        UUID id,
        UUID hospitalId,
        UUID patientId,
        UUID doctorId,
        LocalDateTime appointmentAt,
        AppointmentStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
EOF

  cat > "$base/repository/AppointmentRepository.java" <<EOF
package com.healthcare.appointment.repository;

import com.healthcare.appointment.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface AppointmentRepository extends JpaRepository<Appointment, UUID>, JpaSpecificationExecutor<Appointment> {
}
EOF

  cat > "$base/mapper/AppointmentMapper.java" <<EOF
package com.healthcare.appointment.mapper;

import com.healthcare.appointment.dto.AppointmentCreateRequest;
import com.healthcare.appointment.dto.AppointmentResponse;
import com.healthcare.appointment.dto.AppointmentUpdateRequest;
import com.healthcare.appointment.entity.Appointment;
import org.springframework.stereotype.Component;

@Component
public class AppointmentMapper {

    public Appointment toEntity(AppointmentCreateRequest request) {
        Appointment appointment = new Appointment();
        appointment.setPatientId(request.patientId());
        appointment.setDoctorId(request.doctorId());
        appointment.setAppointmentAt(request.appointmentAt());
        return appointment;
    }

    public void merge(Appointment appointment, AppointmentUpdateRequest request) {
        appointment.setPatientId(request.patientId());
        appointment.setDoctorId(request.doctorId());
        appointment.setAppointmentAt(request.appointmentAt());
    }

    public AppointmentResponse toResponse(Appointment appointment) {
        return new AppointmentResponse(
                appointment.getId(),
                appointment.getHospitalId(),
                appointment.getPatientId(),
                appointment.getDoctorId(),
                appointment.getAppointmentAt(),
                appointment.getStatus(),
                appointment.getCreatedAt(),
                appointment.getUpdatedAt()
        );
    }
}
EOF

  cat > "$base/service/AppointmentService.java" <<EOF
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
EOF

  cat > "$base/service/impl/AppointmentServiceImpl.java" <<EOF
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
        Specification<Appointment> spec = Specification.where((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
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
EOF

  cat > "$base/controller/AppointmentController.java" <<EOF
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

    @PostMapping
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

    @GetMapping
    public ApiResponse<PageResponse<AppointmentResponse>> list(
            @RequestParam(required = false) AppointmentStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Appointments listed", appointmentService.list(status, page, size, sort));
    }
}
EOF
}

write_notification() {
  local base="$ROOT/notification-service/src/main/java/com/healthcare/notification"

  cat > "$base/entity/NotificationStatus.java" <<EOF
package com.healthcare.notification.entity;

public enum NotificationStatus {
    NEW,
    SENT
}
EOF

  cat > "$base/entity/Notification.java" <<EOF
package com.healthcare.notification.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID hospitalId;

    @Column(nullable = false)
    private UUID recipientUserId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, length = 2048)
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationStatus status = NotificationStatus.NEW;

    private Instant sentAt;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getHospitalId() { return hospitalId; }
    public void setHospitalId(UUID hospitalId) { this.hospitalId = hospitalId; }
    public UUID getRecipientUserId() { return recipientUserId; }
    public void setRecipientUserId(UUID recipientUserId) { this.recipientUserId = recipientUserId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public NotificationStatus getStatus() { return status; }
    public void setStatus(NotificationStatus status) { this.status = status; }
    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
EOF

  cat > "$base/dto/NotificationCreateRequest.java" <<EOF
package com.healthcare.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record NotificationCreateRequest(
        UUID hospitalId,
        @NotNull(message = "recipientUserId is required") UUID recipientUserId,
        @NotBlank(message = "title is required") String title,
        @NotBlank(message = "message is required") String message
) {
}
EOF

  cat > "$base/dto/NotificationUpdateRequest.java" <<EOF
package com.healthcare.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record NotificationUpdateRequest(
        UUID hospitalId,
        @NotNull(message = "recipientUserId is required") UUID recipientUserId,
        @NotBlank(message = "title is required") String title,
        @NotBlank(message = "message is required") String message
) {
}
EOF

  cat > "$base/dto/NotificationResponse.java" <<EOF
package com.healthcare.notification.dto;

import com.healthcare.notification.entity.NotificationStatus;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        UUID hospitalId,
        UUID recipientUserId,
        String title,
        String message,
        NotificationStatus status,
        Instant sentAt,
        Instant createdAt,
        Instant updatedAt
) {
}
EOF

  cat > "$base/repository/NotificationRepository.java" <<EOF
package com.healthcare.notification.repository;

import com.healthcare.notification.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID>, JpaSpecificationExecutor<Notification> {
}
EOF

  cat > "$base/mapper/NotificationMapper.java" <<EOF
package com.healthcare.notification.mapper;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.entity.Notification;
import org.springframework.stereotype.Component;

@Component
public class NotificationMapper {

    public Notification toEntity(NotificationCreateRequest request) {
        Notification notification = new Notification();
        notification.setRecipientUserId(request.recipientUserId());
        notification.setTitle(request.title());
        notification.setMessage(request.message());
        return notification;
    }

    public void merge(Notification notification, NotificationUpdateRequest request) {
        notification.setRecipientUserId(request.recipientUserId());
        notification.setTitle(request.title());
        notification.setMessage(request.message());
    }

    public NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getHospitalId(),
                notification.getRecipientUserId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getStatus(),
                notification.getSentAt(),
                notification.getCreatedAt(),
                notification.getUpdatedAt()
        );
    }
}
EOF

  cat > "$base/service/NotificationService.java" <<EOF
package com.healthcare.notification.service;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.util.PageResponse;

import java.util.UUID;

public interface NotificationService {

    NotificationResponse create(NotificationCreateRequest request);

    NotificationResponse getById(UUID id);

    NotificationResponse update(UUID id, NotificationUpdateRequest request);

    void delete(UUID id);

    NotificationResponse send(UUID id);

    PageResponse<NotificationResponse> list(int page, int size, String sort);
}
EOF

  cat > "$base/service/impl/NotificationServiceImpl.java" <<EOF
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
        Specification<Notification> spec = Specification.where((root, query, cb) -> cb.equal(root.get("hospitalId"), hospitalScope));
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
EOF

  cat > "$base/controller/NotificationController.java" <<EOF
package com.healthcare.notification.controller;

import com.healthcare.notification.dto.NotificationCreateRequest;
import com.healthcare.notification.dto.NotificationResponse;
import com.healthcare.notification.dto.NotificationUpdateRequest;
import com.healthcare.notification.service.NotificationService;
import com.healthcare.notification.util.ApiResponse;
import com.healthcare.notification.util.PageResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @PostMapping
    public ApiResponse<NotificationResponse> create(@Valid @RequestBody NotificationCreateRequest request) {
        return ApiResponse.ok("Notification created", notificationService.create(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<NotificationResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok("Notification fetched", notificationService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<NotificationResponse> update(@PathVariable UUID id, @Valid @RequestBody NotificationUpdateRequest request) {
        return ApiResponse.ok("Notification updated", notificationService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        notificationService.delete(id);
        return ApiResponse.ok("Notification deleted", null);
    }

    @PatchMapping("/{id}/send")
    public ApiResponse<NotificationResponse> send(@PathVariable UUID id) {
        return ApiResponse.ok("Notification sent", notificationService.send(id));
    }

    @GetMapping
    public ApiResponse<PageResponse<NotificationResponse>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sort
    ) {
        return ApiResponse.ok("Notifications listed", notificationService.list(page, size, sort));
    }
}
EOF
}

for svc in hospital-service patient-service doctor-service appointment-service notification-service; do
  reset_service "$svc"
done

write_common hospital-service hospital HospitalServiceApplication hospital-service "Hospital Service"
write_common patient-service patient PatientServiceApplication patient-service "Patient Service"
write_common doctor-service doctor DoctorServiceApplication doctor-service "Doctor Service"
write_common appointment-service appointment AppointmentServiceApplication appointment-service "Appointment Service"
write_common notification-service notification NotificationServiceApplication notification-service "Notification Service"

write_hospital
write_patient
write_doctor
write_appointment
write_notification

echo "Scaffold generation complete"
