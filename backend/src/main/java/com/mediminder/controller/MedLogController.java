package com.mediminder.controller;

import com.mediminder.dto.MedLogDTO;
import com.mediminder.security.UserPrincipal;
import com.mediminder.service.MedLogService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/med-logs")
@RequiredArgsConstructor
@Slf4j
public class MedLogController {

    private final MedLogService medLogService;

    @GetMapping
    public ResponseEntity<List<MedLogDTO>> getMedLogs(@AuthenticationPrincipal UserPrincipal principal) {
        List<MedLogDTO> logs = medLogService.getMedLogs(principal.getUserId());
        return ResponseEntity.ok(logs);
    }

    @PostMapping
    public ResponseEntity<List<MedLogDTO>> saveMedLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody List<MedLogDTO> logs) {
        log.info("Saving {} med logs for user {}", logs.size(), principal.getUserId());
        List<MedLogDTO> saved = medLogService.saveMedLogs(principal.getUserId(), logs);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping
    public ResponseEntity<?> deleteAllMedLogs(@AuthenticationPrincipal UserPrincipal principal) {
        log.info("Deleting all med logs for user {}", principal.getUserId());
        medLogService.deleteAllMedLogs(principal.getUserId());
        return ResponseEntity.ok(Map.of("message", "All med logs deleted"));
    }
}
