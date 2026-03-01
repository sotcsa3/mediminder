// MediMinder – Appointments Page

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/appointment.dart';
import '../widgets/appointment_form.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy. MM. dd. (EEEE)', 'hu').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final upcoming = state.upcomingAppointments;
        final past = state.pastAppointments;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Upcoming ──────────────────
                  _SectionTitle(title: '📅 Közelgő'),
                  if (upcoming.isEmpty)
                    const _EmptyState(text: 'Nincs közelgő találkozó')
                  else
                    ...upcoming.map((a) => _ApptCard(
                          appointment: a,
                          isPast: false,
                          formatDate: _formatDate,
                        )),
                  const SizedBox(height: 24),

                  // ── Past ──────────────────────
                  _SectionTitle(title: '📋 Korábbi'),
                  if (past.isEmpty)
                    const _EmptyState(text: 'Még nincs korábbi találkozó')
                  else
                    ...past.map((a) => _ApptCard(
                          appointment: a,
                          isPast: true,
                          formatDate: _formatDate,
                        )),
                ],
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showApptForm(context),
                  icon: const Text('➕', style: TextStyle(fontSize: 18)),
                  label: const Text('Új találkozó hozzáadása'),
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

  void _showApptForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AppointmentForm(),
    );
  }
}

// ── Section Title ───────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor, width: 2),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Appointment Card ────────────────────────
class _ApptCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPast;
  final String Function(String) formatDate;

  const _ApptCard({
    required this.appointment,
    required this.isPast,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isPast ? 0.75 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: isPast ? AppTheme.successColor : AppTheme.secondaryColor,
                width: 5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctor,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (appointment.specialty.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBg,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                appointment.specialty,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isPast)
                      Row(
                        children: [
                          _ActionBtn(
                            icon: Icons.edit,
                            onTap: () => _editAppt(context),
                          ),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            icon: Icons.delete_outline,
                            danger: true,
                            onTap: () => _deleteAppt(context),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details
                _DetailRow(icon: '📅', text: formatDate(appointment.date)),
                const SizedBox(height: 4),
                _DetailRow(icon: '🕐', text: appointment.time),
                if (appointment.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _DetailRow(icon: '📍', text: appointment.location),
                ],
                if (appointment.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    appointment.notes,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editAppt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AppointmentForm(appointment: appointment),
    );
  }

  void _deleteAppt(BuildContext context) async {
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
      context.read<AppState>().deleteAppointment(appointment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Találkozó törölve')),
      );
    }
  }
}

// ── Detail Row ──────────────────────────────
class _DetailRow extends StatelessWidget {
  final String icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action Button ───────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _ActionBtn({
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
        decoration: const BoxDecoration(
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

// ── Empty State ─────────────────────────────
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
