package com.mediminder.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppointmentDTO {
    
    private String id;
    
    @NotBlank(message = "Doctor name is required")
    private String doctorName;
    
    private String specialty;
    
    @NotBlank(message = "Date is required")
    private String date;
    
    @NotBlank(message = "Time is required")
    private String time;
    
    private String location;
    
    private String notes;
    
    private String status;
}
