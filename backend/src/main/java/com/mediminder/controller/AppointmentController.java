package com.mediminder.controller;

import com.mediminder.dto.AppointmentDTO;
import com.mediminder.security.UserPrincipal;
import com.mediminder.service.AppointmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/appointments")
@RequiredArgsConstructor
@Slf4j
public class AppointmentController {

    private final AppointmentService appointmentService;

    @GetMapping
    public ResponseEntity<List<AppointmentDTO>> getAppointments(@AuthenticationPrincipal UserPrincipal principal) {
        List<AppointmentDTO> appointments = appointmentService.getAppointments(principal.getUserId());
        return ResponseEntity.ok(appointments);
    }

    @PostMapping
    public ResponseEntity<List<AppointmentDTO>> saveAppointments(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody List<AppointmentDTO> appointments) {
        log.info("Saving {} appointments for user {}", appointments.size(), principal.getUserId());
        List<AppointmentDTO> saved = appointmentService.saveAppointments(principal.getUserId(), appointments);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping
    public ResponseEntity<?> deleteAllAppointments(@AuthenticationPrincipal UserPrincipal principal) {
        log.info("Deleting all appointments for user {}", principal.getUserId());
        appointmentService.deleteAllAppointments(principal.getUserId());
        return ResponseEntity.ok(Map.of("message", "All appointments deleted"));
    }
}
