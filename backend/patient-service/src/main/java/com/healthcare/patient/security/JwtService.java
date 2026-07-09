package com.healthcare.patient.security;

import com.healthcare.patient.config.AppProperties;
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
        String roleRaw = asString(claims.get("role"));
        UUID userId = parseUuidOrNull(claims.get("userId"));
        UUID hospitalId = parseUuidOrNull(claims.get("hospitalId"));

        if (userId == null) {
            userId = UUID.nameUUIDFromBytes(
                    ("user:" + String.valueOf(claims.get("userId"))).getBytes(StandardCharsets.UTF_8)
            );
        }

        return new CurrentUser(
                userId,
                hospitalId,
                roleRaw == null ? UserRole.PATIENT : UserRole.valueOf(roleRaw)
        );
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static UUID parseUuidOrNull(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = String.valueOf(rawValue).trim();
        if (value.isEmpty()) {
            return null;
        }
        try {
            return UUID.fromString(value);
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }
}
