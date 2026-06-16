package com.healthcare.hospital.repository;

import com.healthcare.hospital.entity.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface HospitalRepository extends JpaRepository<Hospital, UUID>, JpaSpecificationExecutor<Hospital> {
}
