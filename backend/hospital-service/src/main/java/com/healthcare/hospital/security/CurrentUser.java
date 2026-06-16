package com.healthcare.hospital.security;

import java.util.UUID;

public record CurrentUser(UUID userId, UUID hospitalId, UserRole role) {
}
