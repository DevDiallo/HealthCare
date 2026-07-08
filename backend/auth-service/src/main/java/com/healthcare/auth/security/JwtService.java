package com.healthcare.auth.security;

import com.healthcare.auth.config.AppProperties;
import com.healthcare.auth.entity.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

@Service
public class JwtService {

    private final AppProperties properties;
    private final SecretKey secretKey;

    public JwtService(AppProperties properties) {
        this.properties = properties;
        this.secretKey = Keys.hmacShaKeyFor(Decoders.BASE64.decode(properties.getSecret()));
    }

    public String generateAccessToken(Long userId, Long hospitalId, Role role) {
        return generateToken(userId, hospitalId, role, properties.getExpiration(), String.valueOf(userId));
    }

    public String generateRefreshToken(Long userId, Long hospitalId, Role role) {
        String refreshSubject = userId + "-" + UUID.randomUUID().toString().substring(0, 8);
        return generateToken(userId, hospitalId, role, properties.getRefreshExpiration(), refreshSubject);
    }

    public Claims extractClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public CurrentUser extractCurrentUser(String token) {
        Claims claims = extractClaims(token);
        return CurrentUser.builder()
                .userId(claims.get("authUserId", Long.class))
                .hospitalId(claims.get("authHospitalId", Long.class))
                .role(Role.valueOf(claims.get("role", String.class)))
                .build();
    }

    private String generateToken(Long userId, Long hospitalId, Role role, long expiration, String subject) {
        Instant now = Instant.now();
        return Jwts.builder()
                .claims(Map.of(
                        "userId", toScopedUuid("user", userId).toString(),
                        "hospitalId", toScopedUuid("hospital", hospitalId).toString(),
                        "authUserId", userId,
                        "authHospitalId", hospitalId,
                        "role", role.name()
                ))
                .subject(subject)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(expiration)))
                .signWith(secretKey)
                .compact();
    }

    private UUID toScopedUuid(String scope, Long value) {
        return UUID.nameUUIDFromBytes((scope + ":" + value).getBytes());
    }
}