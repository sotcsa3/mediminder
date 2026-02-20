package com.mediminder.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedLogDTO {
    
    private String id;
    
    @NotBlank(message = "Medication ID is required")
    private String medId;
    
    @NotBlank(message = "Date is required")
    private String date;
    
    @NotBlank(message = "Time is required")
    private String time;
    
    private Boolean taken;
    
    private String takenAt;
}
