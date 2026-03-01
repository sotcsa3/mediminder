// MediMinder – Appointment Model

class Appointment {
  final String id;
  final String doctor;
  final String specialty;
  final String date;
  final String time;
  final String location;
  final String notes;

  Appointment({
    required this.id,
    required this.doctor,
    this.specialty = '',
    required this.date,
    required this.time,
    this.location = '',
    this.notes = '',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctor: json['doctor'] as String,
      specialty: json['specialty'] as String? ?? '',
      date: json['date'] as String,
      time: json['time'] as String,
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctor': doctor,
        'specialty': specialty,
        'date': date,
        'time': time,
        'location': location,
        'notes': notes,
      };

  Appointment copyWith({
    String? id,
    String? doctor,
    String? specialty,
    String? date,
    String? time,
    String? location,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  DateTime get dateTime {
    final parts = date.split('-');
    final timeParts = time.split(':');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  bool get isUpcoming {
    return dateTime.isAfter(DateTime.now());
  }

  bool get isPast {
    return dateTime.isBefore(DateTime.now());
  }
}
