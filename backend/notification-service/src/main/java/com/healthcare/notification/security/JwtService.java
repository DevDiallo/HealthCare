package com.healthcare.notification.security;

import com.healthcare.notification.config.AppProperties;
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
