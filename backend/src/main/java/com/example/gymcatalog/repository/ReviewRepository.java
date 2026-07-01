package com.example.gymcatalog.repository;

import com.example.gymcatalog.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByGymIdOrderByCreatedAtDesc(Long gymId);
    Optional<Review> findByGymIdAndUsername(Long gymId, String username);
    void deleteByGymId(Long gymId);
    List<Review> findByGymId(Long gymId);
}