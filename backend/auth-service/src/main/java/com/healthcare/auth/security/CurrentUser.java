package com.healthcare.auth.security;

import com.healthcare.auth.entity.Role;
import lombok.Builder;

@Builder
public record CurrentUser(Long userId, Long hospitalId, Role role) {
}