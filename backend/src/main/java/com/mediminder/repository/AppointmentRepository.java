package com.mediminder.repository;

import com.mediminder.entity.Appointment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    
    List<Appointment> findByUserId(String userId);

    Page<Appointment> findByUserId(String userId, Pageable pageable);
    
    void deleteByUserIdAndIdNotIn(String userId, List<String> ids);
    
    void deleteByUserId(String userId);
}
