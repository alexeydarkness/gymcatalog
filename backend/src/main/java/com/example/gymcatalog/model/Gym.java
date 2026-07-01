package com.example.gymcatalog.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;



@Data
@Entity
@Table(name = "gyms")
public class Gym {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Название не может быть пустым")
    @Size(min = 2, max = 100, message = "Название должно быть от 2 до 100 символов")
    private String name;

    @NotBlank(message = "Адрес не должен быть пустым")
    private String address;
    private String imageUrl;

    @Min(value = 0, message = "Рейтинг не может быть ниже 0")
    @Max(value = 5, message = "Рейтинг не может быть больше 5")
    private double rating;

    @Min(value = 0, message = "Цена не может быть отрицательной")
    private double pricePerMonth;

    @NotBlank(message = "Тип зала не может быть пустой")
    private String type;

    @Column(length = 500)
    @JsonIgnore
    private String amenitiesStr;

    @Transient
    private List<String> amenities = new ArrayList<>();

    @Column(nullable = false)
    private boolean deleted = false;

    @PostLoad
    private void postLoad() {
        if (amenitiesStr != null && !amenitiesStr.isEmpty()) {
            amenities = new ArrayList<>(List.of(amenitiesStr.split(",")));
        } else {
            amenities = new ArrayList<>();
        }
    }

    @PrePersist
    @PreUpdate
    private void preSave() {
        if (amenities != null && !amenities.isEmpty()) {
            amenitiesStr = String.join(",", amenities);
        } else {
            amenitiesStr = "";
        }
    }

 }
