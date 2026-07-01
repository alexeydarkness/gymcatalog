package com.example.gymcatalog.controller;

import com.example.gymcatalog.model.Gym;
import com.example.gymcatalog.repository.GymRepository;
import com.example.gymcatalog.repository.ReviewRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/gyms")
public class GymController {
    private final GymRepository repository;
    private final ReviewRepository reviewRepository;

    public GymController(GymRepository repository, ReviewRepository reviewRepository) {
        this.repository = repository;
        this.reviewRepository = reviewRepository;
    }

    @GetMapping
    public List<Gym> getAll() {
        return repository.findByDeletedFalse();
    }

    @GetMapping("/{id}")
    public Gym getById(@PathVariable Long id) {
        return repository.findById(id).orElseThrow(
                () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Зал с id " + id + "не найден")
        );
    }

    @PostMapping
    public Gym create(@RequestBody Gym gym) {
        gym.setId(null);
        gym.setDeleted(false);
        gym.setRating(0.0); // рейтинг теперь только из отзывов
        return repository.save(gym);
    }

    @PutMapping("/{id}")
    public Gym update(@PathVariable Long id, @RequestBody Gym gym) {
        Gym existing = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Зал с id " + id + " не найден"
                ));
        existing.setName(gym.getName());
        existing.setAddress(gym.getAddress());
        existing.setImageUrl(gym.getImageUrl());
        // existing.setRating(gym.getRating()); — УБРАЛИ, рейтинг считается из отзывов
        existing.setPricePerMonth(gym.getPricePerMonth());
        existing.setType(gym.getType());
        existing.setAmenities(gym.getAmenities());
        existing.setDeleted(gym.isDeleted());

        return repository.save(existing);
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        Gym gym = repository.findById(id).orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Зал с id " + id + " не найден"
        ));

        gym.setDeleted(true);
        repository.save(gym);
        reviewRepository.deleteByGymId(id); // чистим отзывы удалённого зала

        return ResponseEntity.noContent().build();
    }

    @GetMapping("/deleted")
    public List<Gym> getDeleted() {
        return repository.findByDeletedTrue();
    }

    @PutMapping("/{id}/restore")
    public Gym restore(@PathVariable Long id) {
        Gym gym = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Зал с id " + id + " не найден"
                ));
        gym.setDeleted(false);
        return repository.save(gym);
    }
}