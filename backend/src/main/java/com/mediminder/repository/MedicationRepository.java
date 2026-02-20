package com.mediminder.repository;

import com.mediminder.entity.Medication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MedicationRepository extends JpaRepository<Medication, String> {
    
    List<Medication> findByUserId(String userId);
    
    void deleteByUserIdAndIdNotIn(String userId, List<String> ids);
    
    void deleteByUserId(String userId);
}
