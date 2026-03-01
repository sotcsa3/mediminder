// MediMinder – Medication Form Widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MedicationForm extends StatefulWidget {
  final Medication? medication;

  const MedicationForm({super.key, this.medication});

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;
  late String _frequency;
  late List<String> _times;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.medication?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.medication?.dosage ?? '');
    _notesController =
        TextEditingController(text: widget.medication?.notes ?? '');
    _frequency = widget.medication?.frequency ?? 'daily1';
    _times = List.from(widget.medication?.times ?? ['08:00']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTime() {
    setState(() {
      _times.add('12:00');
    });
  }

  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() {
        _times.removeAt(index);
      });
    }
  }

  Future<void> _pickTime(int index) async {
    final parts = _times[index].split(':');
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
        _times[index] =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    final med = Medication(
      id: widget.medication?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      times: _times,
      notes: _notesController.text.trim(),
    );

    if (_isEditing) {
      state.updateMedication(med);
    } else {
      state.addMedication(med);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Gyógyszer frissítve' : 'Gyógyszer hozzáadva',
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
                    _isEditing ? 'Gyógyszer szerkesztése' : 'Új gyógyszer',
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

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Gyógyszer neve *',
                  hintText: 'pl. Metformin',
                ),
                validator: (val) =>
                    val?.isEmpty == true ? 'Kötelező mező' : null,
              ),
              const SizedBox(height: 16),

              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dózis *',
                  hintText: 'pl. 500mg',
                ),
                validator: (val) =>
                    val?.isEmpty == true ? 'Kötelező mező' : null,
              ),
              const SizedBox(height: 16),

              // Frequency
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Gyakoriság',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'daily1', child: Text('Naponta 1x')),
                  DropdownMenuItem(
                      value: 'daily2', child: Text('Naponta 2x')),
                  DropdownMenuItem(
                      value: 'daily3', child: Text('Naponta 3x')),
                  DropdownMenuItem(
                      value: 'weekly', child: Text('Hetente')),
                  DropdownMenuItem(
                      value: 'asneeded',
                      child: Text('Szükség szerint')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              const SizedBox(height: 16),

              // Times
              const Text(
                'Bevételi időpontok',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ..._times.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.surfaceColor,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_times.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppTheme.dangerColor),
                          onPressed: () => _removeTime(entry.key),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add),
                label: const Text('Időpont hozzáadása'),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Megjegyzés',
                  hintText: 'pl. Étkezés után',
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
