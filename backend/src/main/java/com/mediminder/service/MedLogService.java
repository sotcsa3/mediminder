package com.mediminder.service;

import com.mediminder.config.CacheConfig;
import com.mediminder.dto.MedLogDTO;
import com.mediminder.entity.MedLog;
import com.mediminder.entity.User;
import com.mediminder.repository.MedLogRepository;
import com.mediminder.util.IdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MedLogService {

    private final MedLogRepository medLogRepository;
    private final AuthService authService;

    @Cacheable(value = CacheConfig.MED_LOGS_CACHE, key = "#userId")
    public List<MedLogDTO> getMedLogs(String userId) {
        return medLogRepository.findByUserId(userId).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public Page<MedLogDTO> getMedLogs(String userId, Pageable pageable) {
        return medLogRepository.findByUserId(userId, pageable)
                .map(this::toDTO);
    }

    @CacheEvict(value = CacheConfig.MED_LOGS_CACHE, key = "#userId")
    @Transactional
    public List<MedLogDTO> saveMedLogs(String userId, List<MedLogDTO> logs) {
        User user = authService.getUserById(userId);

        // Get existing IDs
        List<String> newIds = logs.stream()
                .map(MedLogDTO::getId)
                .filter(id -> id != null && !id.isEmpty())
                .toList();

        // Delete logs not in the new list
        if (!newIds.isEmpty()) {
            medLogRepository.deleteByUserIdAndIdNotIn(userId, newIds);
        } else {
            medLogRepository.deleteByUserId(userId);
        }

        // Save all logs
        List<MedLog> entitiesToSave = logs.stream()
                .map(dto -> toEntity(dto, user))
                .toList();

        List<MedLog> savedLogs = medLogRepository.saveAll(entitiesToSave);

        return savedLogs.stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    @CacheEvict(value = CacheConfig.MED_LOGS_CACHE, key = "#userId")
    @Transactional
    public void deleteAllMedLogs(String userId) {
        medLogRepository.deleteByUserId(userId);
    }

    private MedLogDTO toDTO(MedLog medLog) {
        return MedLogDTO.builder()
                .id(medLog.getId())
                .medId(medLog.getMedId())
                .date(medLog.getDate())
                .time(medLog.getTime())
                .taken(medLog.getTaken())
                .takenAt(medLog.getTakenAt() != null ? medLog.getTakenAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                        : null)
                .build();
    }

    private MedLog toEntity(MedLogDTO dto, User user) {
        return MedLog.builder()
                .id(dto.getId() != null ? dto.getId() : IdGenerator.generateId())
                .user(user)
                .medId(dto.getMedId())
                .date(dto.getDate())
                .time(dto.getTime())
                .taken(dto.getTaken() != null ? dto.getTaken() : false)
                .takenAt(dto.getTakenAt() != null
                        ? LocalDateTime.parse(dto.getTakenAt(), DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .build();
    }
}
