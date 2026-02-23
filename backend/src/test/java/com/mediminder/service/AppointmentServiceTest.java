package com.mediminder.service;

import com.mediminder.dto.AppointmentDTO;
import com.mediminder.entity.Appointment;
import com.mediminder.entity.User;
import com.mediminder.repository.AppointmentRepository;
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

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTest {

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private AuthService authService;

    @InjectMocks
    private AppointmentService appointmentService;

    private User testUser;
    private Appointment testAppointment;
    private AppointmentDTO testDTO;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id("user-123")
                .email("test@example.com")
                .build();

        testAppointment = Appointment.builder()
                .id("apt-1")
                .user(testUser)
                .doctorName("Dr. Smith")
                .specialty("Cardiology")
                .date("2026-03-01")
                .time("10:00")
                .location("Hospital A")
                .notes("Annual checkup")
                .status("pending")
                .build();

        testDTO = AppointmentDTO.builder()
                .id("apt-1")
                .doctorName("Dr. Smith")
                .specialty("Cardiology")
                .date("2026-03-01")
                .time("10:00")
                .location("Hospital A")
                .notes("Annual checkup")
                .status("pending")
                .build();
    }

    @Nested
    @DisplayName("getAppointments")
    class GetAppointmentsTests {

        @Test
        @DisplayName("should return list of appointments for user")
        void getAppointmentsSuccess() {
            when(appointmentRepository.findByUserId("user-123"))
                    .thenReturn(List.of(testAppointment));

            List<AppointmentDTO> result = appointmentService.getAppointments("user-123");

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getDoctorName()).isEqualTo("Dr. Smith");
            assertThat(result.get(0).getSpecialty()).isEqualTo("Cardiology");
            assertThat(result.get(0).getStatus()).isEqualTo("pending");
        }

        @Test
        @DisplayName("should return empty list when no appointments")
        void getAppointmentsEmpty() {
            when(appointmentRepository.findByUserId("user-123"))
                    .thenReturn(Collections.emptyList());

            List<AppointmentDTO> result = appointmentService.getAppointments("user-123");

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should return paginated appointments")
        void getAppointmentsPaginated() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<Appointment> page = new PageImpl<>(List.of(testAppointment), pageable, 1);
            when(appointmentRepository.findByUserId("user-123", pageable)).thenReturn(page);

            Page<AppointmentDTO> result = appointmentService.getAppointments("user-123", pageable);

            assertThat(result.getTotalElements()).isEqualTo(1);
            assertThat(result.getContent().get(0).getDoctorName()).isEqualTo("Dr. Smith");
        }
    }

    @Nested
    @DisplayName("saveAppointments")
    class SaveAppointmentsTests {

        @Test
        @DisplayName("should save appointments and delete removed ones")
        void saveAppointmentsSuccess() {
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(appointmentRepository.saveAll(anyList())).thenReturn(List.of(testAppointment));

            List<AppointmentDTO> result = appointmentService.saveAppointments("user-123", List.of(testDTO));

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getDoctorName()).isEqualTo("Dr. Smith");
            verify(appointmentRepository).deleteByUserIdAndIdNotIn(eq("user-123"), anyList());
            verify(appointmentRepository).saveAll(anyList());
        }

        @Test
        @DisplayName("should delete all when saving new appointments without IDs")
        void saveAppointmentsNewOnly() {
            AppointmentDTO newDTO = AppointmentDTO.builder()
                    .doctorName("Dr. Jones")
                    .date("2026-04-01")
                    .time("14:00")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            Appointment newApt = Appointment.builder()
                    .id("generated-id")
                    .user(testUser)
                    .doctorName("Dr. Jones")
                    .date("2026-04-01")
                    .time("14:00")
                    .status("pending")
                    .build();
            when(appointmentRepository.saveAll(anyList())).thenReturn(List.of(newApt));

            appointmentService.saveAppointments("user-123", List.of(newDTO));

            verify(appointmentRepository).deleteByUserId("user-123");
            verify(appointmentRepository, never()).deleteByUserIdAndIdNotIn(anyString(), anyList());
        }

        @Test
        @DisplayName("should default status to pending when null")
        void saveAppointmentsDefaultStatus() {
            AppointmentDTO dtoNoStatus = AppointmentDTO.builder()
                    .id("apt-new")
                    .doctorName("Dr. Jones")
                    .date("2026-04-01")
                    .time("14:00")
                    .build();
            when(authService.getUserById("user-123")).thenReturn(testUser);
            when(appointmentRepository.saveAll(anyList())).thenAnswer(invocation -> {
                List<Appointment> apts = invocation.getArgument(0);
                return apts;
            });

            appointmentService.saveAppointments("user-123", List.of(dtoNoStatus));

            verify(appointmentRepository).saveAll(argThat(apts -> {
                Appointment apt = ((List<Appointment>) apts).get(0);
                return "pending".equals(apt.getStatus());
            }));
        }
    }

    @Nested
    @DisplayName("deleteAllAppointments")
    class DeleteAppointmentsTests {

        @Test
        @DisplayName("should delete all appointments for user")
        void deleteAllSuccess() {
            appointmentService.deleteAllAppointments("user-123");

            verify(appointmentRepository).deleteByUserId("user-123");
        }
    }
}
