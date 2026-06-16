package com.healthcare.doctor.util;

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
