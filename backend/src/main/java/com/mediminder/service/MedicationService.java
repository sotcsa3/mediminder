package com.mediminder.service;

import com.mediminder.config.CacheConfig;
import com.mediminder.dto.MedicationDTO;
import com.mediminder.entity.Medication;
import com.mediminder.entity.User;
import com.mediminder.repository.MedicationRepository;
import com.mediminder.util.IdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MedicationService {

    private final MedicationRepository medicationRepository;
    private final AuthService authService;

    @Cacheable(value = CacheConfig.MEDICATIONS_CACHE, key = "#userId")
    public List<MedicationDTO> getMedications(String userId) {
        return medicationRepository.findByUserId(userId).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public Page<MedicationDTO> getMedications(String userId, Pageable pageable) {
        return medicationRepository.findByUserId(userId, pageable)
                .map(this::toDTO);
    }

    @CacheEvict(value = CacheConfig.MEDICATIONS_CACHE, key = "#userId")
    @Transactional
    public List<MedicationDTO> saveMedications(String userId, List<MedicationDTO> medications) {
        User user = authService.getUserById(userId);

        // Get existing IDs
        List<String> newIds = medications.stream()
                .map(MedicationDTO::getId)
                .filter(id -> id != null && !id.isEmpty())
                .toList();

        // Delete medications not in the new list
        if (!newIds.isEmpty()) {
            medicationRepository.deleteByUserIdAndIdNotIn(userId, newIds);
        } else {
            medicationRepository.deleteByUserId(userId);
        }

        // Save all medications
        List<Medication> entitiesToSave = medications.stream()
                .map(dto -> toEntity(dto, user))
                .toList();

        List<Medication> savedMedications = medicationRepository.saveAll(entitiesToSave);

        return savedMedications.stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    @CacheEvict(value = CacheConfig.MEDICATIONS_CACHE, key = "#userId")
    @Transactional
    public void deleteAllMedications(String userId) {
        medicationRepository.deleteByUserId(userId);
    }

    private MedicationDTO toDTO(Medication medication) {
        return MedicationDTO.builder()
                .id(medication.getId())
                .name(medication.getName())
                .dosage(medication.getDosage())
                .frequency(medication.getFrequency())
                .times(medication.getTimes())
                .notes(medication.getNotes())
                .build();
    }

    private Medication toEntity(MedicationDTO dto, User user) {
        return Medication.builder()
                .id(dto.getId() != null ? dto.getId() : IdGenerator.generateId())
                .user(user)
                .name(dto.getName())
                .dosage(dto.getDosage())
                .frequency(dto.getFrequency())
                .times(dto.getTimes())
                .notes(dto.getNotes())
                .build();
    }
}
