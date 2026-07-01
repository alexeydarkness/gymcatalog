package com.example.gymcatalog.repository;

import com.example.gymcatalog.model.Gym;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GymRepository extends JpaRepository<Gym, Long> {
    List<Gym> findByDeletedFalse();
    List<Gym> findByDeletedTrue();
}
