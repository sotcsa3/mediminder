package com.mediminder.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "med_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedLog {
    
    @Id
    @Column(name = "id", nullable = false)
    private String id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(name = "med_id", nullable = false)
    private String medId;
    
    @Column(name = "date", nullable = false)
    private String date; // YYYY-MM-DD
    
    @Column(name = "time", nullable = false)
    private String time; // HH:MM
    
    @Column(name = "taken")
    @Builder.Default
    private Boolean taken = false;
    
    @Column(name = "taken_at")
    private LocalDateTime takenAt;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
