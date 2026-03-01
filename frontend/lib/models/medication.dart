// MediMinder – Medication Model

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final String notes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    this.frequency = 'daily1',
    this.times = const ['08:00'],
    this.notes = '',
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String? ?? 'daily1',
      times: (json['times'] as List<dynamic>?)?.cast<String>() ?? ['08:00'],
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'times': times,
        'notes': notes,
      };

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      notes: notes ?? this.notes,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily1':
        return 'Naponta 1x';
      case 'daily2':
        return 'Naponta 2x';
      case 'daily3':
        return 'Naponta 3x';
      case 'weekly':
        return 'Hetente';
      case 'asneeded':
        return 'Szükség szerint';
      default:
        return frequency;
    }
  }
}
