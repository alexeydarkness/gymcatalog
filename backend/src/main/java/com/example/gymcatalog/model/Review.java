package com.example.gymcatalog.model;


import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "reviews")
public class Review {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long gymId;

    @NotBlank
    @Column(nullable = false)
    private String username;

    @Min(value = 1, message = "Оценка не может быть меньше 1")
    @Max(value = 5, message = "Оценка не может быть больше 5")
    private int rating;


    @Size(max = 1000, message = "Комментарий не должен превышать 1000 символов")
    @Column(length = 1000)
    private String text;


    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    private void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
