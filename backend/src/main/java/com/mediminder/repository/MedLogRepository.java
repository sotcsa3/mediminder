package com.mediminder.repository;

import com.mediminder.entity.MedLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MedLogRepository extends JpaRepository<MedLog, String> {
    
    List<MedLog> findByUserId(String userId);

    Page<MedLog> findByUserId(String userId, Pageable pageable);
    
    void deleteByUserIdAndIdNotIn(String userId, List<String> ids);
    
    void deleteByUserId(String userId);
}
