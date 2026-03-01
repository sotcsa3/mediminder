// MediMinder – Medications Page

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/medication.dart';
import '../widgets/medication_form.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final meds = state.medications;

        return Column(
          children: [
            // Day selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _DayButton(
                      label: 'Ma',
                      active: !_showAll,
                      onTap: () => setState(() => _showAll = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DayButton(
                      label: 'Összes',
                      active: _showAll,
                      onTap: () => setState(() => _showAll = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medications list
            Expanded(
              child: meds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💊',
                              style: TextStyle(fontSize: 50)),
                          const SizedBox(height: 12),
                          const Text(
                            'Még nincs gyógyszer felvéve',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nyomja meg az alábbi gombot az első gyógyszer hozzáadásához',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: meds.length,
                      itemBuilder: (context, index) {
                        return _MedCard(
                          medication: meds[index],
                          today: today,
                          showTimes: !_showAll,
                        );
                      },
                    ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMedForm(context),
                  icon: const Text('➕', style: TextStyle(fontSize: 18)),
                  label: const Text('Új gyógyszer hozzáadása'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMedForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MedicationForm(),
    );
  }
}

// ── Day Selector Button ─────────────────────
class _DayButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Medication Card ────────────────────────
class _MedCard extends StatelessWidget {
  final Medication medication;
  final String today;
  final bool showTimes;

  const _MedCard({
    required this.medication,
    required this.today,
    required this.showTimes,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final allTaken = state.areMedAllTimesTakenToday(medication.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: allTaken ? AppTheme.successColor : AppTheme.primaryColor,
              width: 5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          medication.dosage,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.edit,
                        onTap: () => _editMed(context),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        danger: true,
                        onTap: () => _deleteMed(context),
                      ),
                    ],
                  ),
                ],
              ),

              // Schedule
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Text('🕐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      medication.frequencyLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Notes
              if (medication.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    medication.notes,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              if (showTimes) ...[
                const SizedBox(height: 12),

                // Time chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: medication.times.map((time) {
                    final taken =
                        state.isMedTaken(medication.id, today, time);
                    return InkWell(
                      onTap: () =>
                          state.toggleMedTaken(medication.id, today, time),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              taken ? AppTheme.successBg : AppTheme.warningBg,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: taken
                                ? AppTheme.successColor
                                : AppTheme.secondaryLight,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              taken ? '✅' : '⏰',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: taken
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Take all button
                SizedBox(
                  width: double.infinity,
                  child: allTaken
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '✅ Ma mind bevéve',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () =>
                              state.markAllTimesToday(medication.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '💊 Beveszem mind',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editMed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MedicationForm(medication: medication),
    );
  }

  void _deleteMed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text('Biztosan törli?'),
          ],
        ),
        content: const Text('Ez a művelet nem vonható vissza.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AppState>().deleteMedication(medication.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gyógyszer törölve')),
      );
    }
  }
}

// ── Action Button ───────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.bgColor,
        ),
        child: Icon(
          icon,
          size: 18,
          color: danger ? AppTheme.dangerColor : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
