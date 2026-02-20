package com.mediminder.service;

import com.mediminder.dto.AppointmentDTO;
import com.mediminder.entity.Appointment;
import com.mediminder.entity.User;
import com.mediminder.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AppointmentService {
    
    private final AppointmentRepository appointmentRepository;
    private final AuthService authService;
    
    public List<AppointmentDTO> getAppointments(String userId) {
        return appointmentRepository.findByUserId(userId).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }
    
    @Transactional
    public List<AppointmentDTO> saveAppointments(String userId, List<AppointmentDTO> appointments) {
        User user = authService.getUserById(userId);
        
        // Get existing IDs
        List<String> newIds = appointments.stream()
                .map(AppointmentDTO::getId)
                .filter(id -> id != null && !id.isEmpty())
                .toList();
        
        // Delete appointments not in the new list
        if (!newIds.isEmpty()) {
            appointmentRepository.deleteByUserIdAndIdNotIn(userId, newIds);
        } else {
            appointmentRepository.deleteByUserId(userId);
        }
        
        // Save all appointments
        List<Appointment> savedAppointments = appointments.stream()
                .map(dto -> toEntity(dto, user))
                .map(appointmentRepository::save)
                .toList();
        
        return savedAppointments.stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }
    
    @Transactional
    public void deleteAllAppointments(String userId) {
        appointmentRepository.deleteByUserId(userId);
    }
    
    private AppointmentDTO toDTO(Appointment appointment) {
        return AppointmentDTO.builder()
                .id(appointment.getId())
                .doctorName(appointment.getDoctorName())
                .specialty(appointment.getSpecialty())
                .date(appointment.getDate())
                .time(appointment.getTime())
                .location(appointment.getLocation())
                .notes(appointment.getNotes())
                .status(appointment.getStatus())
                .build();
    }
    
    private Appointment toEntity(AppointmentDTO dto, User user) {
        return Appointment.builder()
                .id(dto.getId() != null ? dto.getId() : generateId())
                .user(user)
                .doctorName(dto.getDoctorName())
                .specialty(dto.getSpecialty())
                .date(dto.getDate())
                .time(dto.getTime())
                .location(dto.getLocation())
                .notes(dto.getNotes())
                .status(dto.getStatus() != null ? dto.getStatus() : "pending")
                .build();
    }
    
    private String generateId() {
        return Long.toString(System.currentTimeMillis(), 36) + 
               Long.toString((long) (Math.random() * 1000000000L), 36);
    }
}
