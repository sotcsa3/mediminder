// MediMinder – Appointment Form Widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AppointmentForm extends StatefulWidget {
  final Appointment? appointment;

  const AppointmentForm({super.key, this.appointment});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doctorController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late String _specialty;
  late String _date;
  late String _time;

  bool get _isEditing => widget.appointment != null;

  static const List<String> _specialties = [
    '',
    'Belgyógyászat',
    'Bőrgyógyászat',
    'Fogászat',
    'Fül-orr-gégészet',
    'Háziorvos',
    'Kardiológia',
    'Neurológia',
    'Nőgyógyászat',
    'Ortopédia',
    'Szemészet',
    'Urológia',
    'Egyéb',
  ];

  @override
  void initState() {
    super.initState();
    _doctorController =
        TextEditingController(text: widget.appointment?.doctor ?? '');
    _locationController =
        TextEditingController(text: widget.appointment?.location ?? '');
    _notesController =
        TextEditingController(text: widget.appointment?.notes ?? '');
    _specialty = widget.appointment?.specialty ?? '';
    _date = widget.appointment?.date ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    _time = widget.appointment?.time ?? '10:00';
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('hu'),
    );

    if (date != null) {
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _time =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    final appt = Appointment(
      id: widget.appointment?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      doctor: _doctorController.text.trim(),
      specialty: _specialty,
      date: _date,
      time: _time,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (_isEditing) {
      state.updateAppointment(appt);
    } else {
      state.addAppointment(appt);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Találkozó frissítve' : 'Találkozó hozzáadva',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Találkozó szerkesztése' : 'Új találkozó',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Doctor
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Orvos neve *',
                  hintText: 'pl. Dr. Kovács Péter',
                ),
                validator: (val) =>
                    val?.isEmpty == true ? 'Kötelező mező' : null,
              ),
              const SizedBox(height: 16),

              // Specialty
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(
                  labelText: 'Szakterület',
                ),
                items: _specialties
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.isEmpty ? 'Válasszon...' : s),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _specialty = val);
                },
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.surfaceColor,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dátum *',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(_date, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.surfaceColor,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Időpont *',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(_time, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Helyszín',
                  hintText: 'pl. Klinika, 3. emelet',
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Megjegyzés',
                  hintText: 'pl. Vérvétel eredményét vinni',
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Mégse'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Mentés'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
