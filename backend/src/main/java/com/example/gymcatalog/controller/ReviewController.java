package com.example.gymcatalog.controller;

import com.example.gymcatalog.model.Gym;
import com.example.gymcatalog.model.Review;
import com.example.gymcatalog.repository.GymRepository;
import com.example.gymcatalog.repository.ReviewRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
public class ReviewController {
    private final ReviewRepository reviewRepository;
    private final GymRepository gymRepository;

    public ReviewController(ReviewRepository reviewRepository, GymRepository gymRepository) {
        this.reviewRepository = reviewRepository;
        this.gymRepository = gymRepository;
    }

    @GetMapping("/gyms/{gymId}/reviews")
    public List<Review> getReviews(@PathVariable Long gymId) {
        return reviewRepository.findByGymIdOrderByCreatedAtDesc(gymId);
    }

    @PostMapping("/gyms/{gymId}/reviews")
    public ResponseEntity<Review> addReview(
            @PathVariable Long gymId,
            @Valid @RequestBody Review review
    ) {
        gymRepository.findById(gymId).orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Зал с id " + gymId + " не найден"
        ));

        review.setGymId(gymId);

        Optional<Review> existing = reviewRepository.findByGymIdAndUsername(gymId, review.getUsername());
        if (existing.isPresent()) {
            Review r = existing.get();
            r.setRating(review.getRating());
            r.setText(review.getText());
            review = reviewRepository.save(r);
        } else {
            review.setId(null);
            review = reviewRepository.save(review);
        }

        recalcGymRating(gymId);
        return ResponseEntity.status(HttpStatus.CREATED).body(review);
    }

    @DeleteMapping("/reviews/{id}")
    public ResponseEntity<?> deleteReview(
            @PathVariable Long id,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String role
    ) {
        System.out.println("DELETE review id=" + id + ", username=" + username + ", role=" + role);

        Review review = reviewRepository.findById(id).orElse(null);
        if (review == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Отзыв с id " + id + " не найден в БД"));
        }

        if (!"admin".equals(role) && !review.getUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Нельзя удалять чужие отзывы"));
        }

        Long gymId = review.getGymId();
        reviewRepository.deleteById(id);
        recalcGymRating(gymId);
        return ResponseEntity.noContent().build();
    }
    private void recalcGymRating(Long gymId) {
        gymRepository.findById(gymId).ifPresent(gym -> {
            List<Review> reviews = reviewRepository.findByGymId(gymId);
            double avg = reviews.isEmpty()
                    ? 0.0
                    : reviews.stream().mapToInt(Review::getRating).average().orElse(0.0);
            gym.setRating(Math.round(avg * 10.0) / 10.0);
            gymRepository.save(gym);
        });
    }
}