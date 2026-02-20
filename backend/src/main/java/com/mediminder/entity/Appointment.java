package com.mediminder.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "appointments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Appointment {
    
    @Id
    @Column(name = "id", nullable = false)
    private String id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(name = "doctor_name", nullable = false)
    private String doctorName;
    
    @Column(name = "specialty")
    private String specialty;
    
    @Column(name = "date", nullable = false)
    private String date; // YYYY-MM-DD
    
    @Column(name = "time", nullable = false)
    private String time; // HH:MM
    
    @Column(name = "location")
    private String location;
    
    @Column(name = "notes")
    private String notes;
    
    @Column(name = "status")
    @Builder.Default
    private String status = "pending"; // pending, done, missed
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
