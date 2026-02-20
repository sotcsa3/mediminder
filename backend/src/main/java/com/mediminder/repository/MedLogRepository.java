package com.mediminder.repository;

import com.mediminder.entity.MedLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MedLogRepository extends JpaRepository<MedLog, String> {
    
    List<MedLog> findByUserId(String userId);
    
    void deleteByUserIdAndIdNotIn(String userId, List<String> ids);
    
    void deleteByUserId(String userId);
}
