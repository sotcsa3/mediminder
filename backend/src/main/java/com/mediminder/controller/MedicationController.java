package com.mediminder.controller;

import com.mediminder.dto.MedicationDTO;
import com.mediminder.security.UserPrincipal;
import com.mediminder.service.MedicationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/medications")
@RequiredArgsConstructor
@Slf4j
public class MedicationController {
    
    private final MedicationService medicationService;
    
    @GetMapping
    public ResponseEntity<List<MedicationDTO>> getMedications(@AuthenticationPrincipal UserPrincipal principal) {
        List<MedicationDTO> medications = medicationService.getMedications(principal.getUserId());
        return ResponseEntity.ok(medications);
    }
    
    @PostMapping
    public ResponseEntity<List<MedicationDTO>> saveMedications(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody List<MedicationDTO> medications) {
        log.info("Saving {} medications for user {}", medications.size(), principal.getUserId());
        List<MedicationDTO> saved = medicationService.saveMedications(principal.getUserId(), medications);
        return ResponseEntity.ok(saved);
    }
    
    @DeleteMapping
    public ResponseEntity<?> deleteAllMedications(@AuthenticationPrincipal UserPrincipal principal) {
        log.info("Deleting all medications for user {}", principal.getUserId());
        medicationService.deleteAllMedications(principal.getUserId());
        return ResponseEntity.ok(Map.of("message", "All medications deleted"));
    }
}
