package com.healthcare.doctor.security;

import java.util.UUID;

public record CurrentUser(UUID userId, UUID hospitalId, UserRole role) {
}
