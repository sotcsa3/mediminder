package com.mediminder.service;

import com.mediminder.dto.MedicationDTO;
import com.mediminder.entity.Medication;
import com.mediminder.entity.User;
import com.mediminder.repository.MedicationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MedicationServiceTest {

    @Mock
    private MedicationRepository medicationRepository;

    @Mock
    private AuthService authService;

    @InjectMocks
    private MedicationService medicationService;

    private User testUser;
    private Medication testMedication;
    private MedicationDTO testDTO;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id("user-123")
                .email("test@example.com")
                .build();

        testMedication = Medication.builder()
                .id("med-1")
                .user(testUser)
                .name("Aspirin")
                .dosage("100mg")
                .frequency("daily")
                .times(List.of("08:00", "20:00"))
                .notes("Take with food")
                .build();

        testDTO = MedicationDTO.builder()
                .id("med-1")
                .name("Aspirin")
                .dosage("100mg")
                .frequency("daily")
                .times(List.of("08:00", "20:00"))
                .notes("Take with food")
                .build();
    }

    @Nested
    @DisplayName("getMedications")
    class GetMedicationsTests {

        @Test
        @DisplayName("should return list of medications for user")
        void getMedicationsSuccess() {
            when(medicationRepository.findByUserId("user-123"))
                    .thenReturn(List.of(testMedication));

            List<MedicationDTO> result = medicationService.getMedications("user-123");

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getName()).isEqualTo("Aspirin");
            assertThat(result.get(0).getDosage()).isEqualTo("100mg");
            assertThat(result.get(0).getTimes()).containsExactly("08:00", "20:00");
        }

        @Test
        @DisplayName("should return empty list when no medications")
        void getMedicationsEmpty() {
            when(medicationRepository.findByUserId("user-123"))
                    .thenReturn(Collections.emptyList());

            List<MedicationDTO> result = medicationService.getMedications("user-123");

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should return paginated medications")
        void getMedicationsPaginated() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<Medication> page = new PageImpl<>(List.of(testMedication), pageable, 1);
            when(medicationRepository.findByUserId("user-123", pageable)).thenReturn(page);

            Page<MedicationDTO> result = medicationService.getMedications("user-123", pageable);

            assertThat(result.getTotalElements()).isEqualTo(1);
            assertThat(result.getContent().get(0).getName()).isEqualTo("Aspirin");
        }
    }

    @Nested
    @DisplayName("saveMedications")
    class SaveMedicationsTests {

        @Test
        @DisplayName("should save medications and delete removed ones")
        void saveMedicationsSuccess() {
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medicationRepository.saveAll(anyList())).thenReturn(List.of(testMedication));

            List<MedicationDTO> result = medicationService.saveMedications("user-123", List.of(testDTO));

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getName()).isEqualTo("Aspirin");
            verify(medicationRepository).deleteByUserIdAndIdNotIn(eq("user-123"), anyList());
            verify(medicationRepository).saveAll(anyList());
        }

        @Test
        @DisplayName("should delete all when saving empty list with no IDs")
        void saveMedicationsEmptyIds() {
            MedicationDTO newDTO = MedicationDTO.builder()
                    .name("New Med")
                    .dosage("50mg")
                    .frequency("weekly")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            Medication newMed = Medication.builder()
                    .id("generated-id")
                    .user(testUser)
                    .name("New Med")
                    .dosage("50mg")
                    .frequency("weekly")
                    .build();
            when(medicationRepository.saveAll(anyList())).thenReturn(List.of(newMed));

            List<MedicationDTO> result = medicationService.saveMedications("user-123", List.of(newDTO));

            assertThat(result).hasSize(1);
            verify(medicationRepository).deleteByUserId("user-123");
            verify(medicationRepository, never()).deleteByUserIdAndIdNotIn(anyString(), anyList());
        }

        @Test
        @DisplayName("should generate ID for new medication without ID")
        void saveMedicationsGenerateId() {
            MedicationDTO dtoWithoutId = MedicationDTO.builder()
                    .name("New Med")
                    .dosage("50mg")
                    .frequency("daily")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medicationRepository.saveAll(anyList())).thenAnswer(invocation -> {
                List<Medication> meds = invocation.getArgument(0);
                assertThat(meds.get(0).getId()).isNotNull().isNotEmpty();
                return meds;
            });

            medicationService.saveMedications("user-123", List.of(dtoWithoutId));

            verify(medicationRepository).saveAll(argThat(meds -> {
                Medication med = ((List<Medication>) meds).get(0);
                return med.getId() != null && !med.getId().isEmpty();
            }));
        }
    }

    @Nested
    @DisplayName("deleteAllMedications")
    class DeleteMedicationsTests {

        @Test
        @DisplayName("should delete all medications for user")
        void deleteAllSuccess() {
            medicationService.deleteAllMedications("user-123");

            verify(medicationRepository).deleteByUserId("user-123");
        }
    }
}
