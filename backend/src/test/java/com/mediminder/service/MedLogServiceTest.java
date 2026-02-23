package com.mediminder.service;

import com.mediminder.dto.MedLogDTO;
import com.mediminder.entity.MedLog;
import com.mediminder.entity.User;
import com.mediminder.repository.MedLogRepository;
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

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MedLogServiceTest {

    @Mock
    private MedLogRepository medLogRepository;

    @Mock
    private AuthService authService;

    @InjectMocks
    private MedLogService medLogService;

    private User testUser;
    private MedLog testMedLog;
    private MedLogDTO testDTO;
    private LocalDateTime takenAtTime;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id("user-123")
                .email("test@example.com")
                .build();

        takenAtTime = LocalDateTime.of(2026, 2, 23, 8, 30, 0);

        testMedLog = MedLog.builder()
                .id("log-1")
                .user(testUser)
                .medId("med-1")
                .date("2026-02-23")
                .time("08:00")
                .taken(true)
                .takenAt(takenAtTime)
                .build();

        testDTO = MedLogDTO.builder()
                .id("log-1")
                .medId("med-1")
                .date("2026-02-23")
                .time("08:00")
                .taken(true)
                .takenAt("2026-02-23T08:30:00")
                .build();
    }

    @Nested
    @DisplayName("getMedLogs")
    class GetMedLogsTests {

        @Test
        @DisplayName("should return list of med logs for user")
        void getMedLogsSuccess() {
            when(medLogRepository.findByUserId("user-123"))
                    .thenReturn(List.of(testMedLog));

            List<MedLogDTO> result = medLogService.getMedLogs("user-123");

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getMedId()).isEqualTo("med-1");
            assertThat(result.get(0).getDate()).isEqualTo("2026-02-23");
            assertThat(result.get(0).getTaken()).isTrue();
            assertThat(result.get(0).getTakenAt()).isEqualTo("2026-02-23T08:30:00");
        }

        @Test
        @DisplayName("should handle null takenAt in DTO conversion")
        void getMedLogsNullTakenAt() {
            MedLog logNoTakenAt = MedLog.builder()
                    .id("log-2")
                    .user(testUser)
                    .medId("med-1")
                    .date("2026-02-23")
                    .time("08:00")
                    .taken(false)
                    .takenAt(null)
                    .build();
            when(medLogRepository.findByUserId("user-123"))
                    .thenReturn(List.of(logNoTakenAt));

            List<MedLogDTO> result = medLogService.getMedLogs("user-123");

            assertThat(result.get(0).getTakenAt()).isNull();
            assertThat(result.get(0).getTaken()).isFalse();
        }

        @Test
        @DisplayName("should return empty list when no logs")
        void getMedLogsEmpty() {
            when(medLogRepository.findByUserId("user-123"))
                    .thenReturn(Collections.emptyList());

            List<MedLogDTO> result = medLogService.getMedLogs("user-123");

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should return paginated med logs")
        void getMedLogsPaginated() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<MedLog> page = new PageImpl<>(List.of(testMedLog), pageable, 1);
            when(medLogRepository.findByUserId("user-123", pageable)).thenReturn(page);

            Page<MedLogDTO> result = medLogService.getMedLogs("user-123", pageable);

            assertThat(result.getTotalElements()).isEqualTo(1);
            assertThat(result.getContent().get(0).getMedId()).isEqualTo("med-1");
        }
    }

    @Nested
    @DisplayName("saveMedLogs")
    class SaveMedLogsTests {

        @Test
        @DisplayName("should save med logs and delete removed ones")
        void saveMedLogsSuccess() {
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medLogRepository.saveAll(anyList())).thenReturn(List.of(testMedLog));

            List<MedLogDTO> result = medLogService.saveMedLogs("user-123", List.of(testDTO));

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getMedId()).isEqualTo("med-1");
            verify(medLogRepository).deleteByUserIdAndIdNotIn(eq("user-123"), anyList());
            verify(medLogRepository).saveAll(anyList());
        }

        @Test
        @DisplayName("should delete all when saving logs without IDs")
        void saveMedLogsNewOnly() {
            MedLogDTO newDTO = MedLogDTO.builder()
                    .medId("med-2")
                    .date("2026-02-23")
                    .time("12:00")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            MedLog newLog = MedLog.builder()
                    .id("generated-id")
                    .user(testUser)
                    .medId("med-2")
                    .date("2026-02-23")
                    .time("12:00")
                    .taken(false)
                    .build();
            when(medLogRepository.saveAll(anyList())).thenReturn(List.of(newLog));

            medLogService.saveMedLogs("user-123", List.of(newDTO));

            verify(medLogRepository).deleteByUserId("user-123");
            verify(medLogRepository, never()).deleteByUserIdAndIdNotIn(anyString(), anyList());
        }

        @Test
        @DisplayName("should default taken to false when null")
        void saveMedLogsDefaultTaken() {
            MedLogDTO dtoNullTaken = MedLogDTO.builder()
                    .id("log-new")
                    .medId("med-1")
                    .date("2026-02-23")
                    .time("08:00")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medLogRepository.saveAll(anyList())).thenAnswer(invocation -> invocation.getArgument(0));

            medLogService.saveMedLogs("user-123", List.of(dtoNullTaken));

            verify(medLogRepository).saveAll(argThat(logs -> {
                MedLog log = ((List<MedLog>) logs).get(0);
                return log.getTaken() == false;
            }));
        }

        @Test
        @DisplayName("should parse takenAt datetime string correctly")
        void saveMedLogsParseTakenAt() {
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medLogRepository.saveAll(anyList())).thenAnswer(invocation -> {
                List<MedLog> logs = invocation.getArgument(0);
                MedLog log = logs.get(0);
                assertThat(log.getTakenAt()).isEqualTo(takenAtTime);
                return logs;
            });

            medLogService.saveMedLogs("user-123", List.of(testDTO));

            verify(medLogRepository).saveAll(anyList());
        }

        @Test
        @DisplayName("should handle null takenAt in entity conversion")
        void saveMedLogsNullTakenAt() {
            MedLogDTO dtoNoTakenAt = MedLogDTO.builder()
                    .id("log-1")
                    .medId("med-1")
                    .date("2026-02-23")
                    .time("08:00")
                    .taken(false)
                    .takenAt(null)
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(medLogRepository.saveAll(anyList())).thenAnswer(invocation -> {
                List<MedLog> logs = invocation.getArgument(0);
                assertThat(logs.get(0).getTakenAt()).isNull();
                return logs;
            });

            medLogService.saveMedLogs("user-123", List.of(dtoNoTakenAt));

            verify(medLogRepository).saveAll(anyList());
        }
    }

    @Nested
    @DisplayName("deleteAllMedLogs")
    class DeleteMedLogsTests {

        @Test
        @DisplayName("should delete all med logs for user")
        void deleteAllSuccess() {
            medLogService.deleteAllMedLogs("user-123");

            verify(medLogRepository).deleteByUserId("user-123");
        }
    }
}
