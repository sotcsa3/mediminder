package com.mediminder.repository;

import com.mediminder.entity.Medication;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MedicationRepository extends JpaRepository<Medication, String> {
    
    List<Medication> findByUserId(String userId);

    Page<Medication> findByUserId(String userId, Pageable pageable);
    
    void deleteByUserIdAndIdNotIn(String userId, List<String> ids);
    
    void deleteByUserId(String userId);
}
