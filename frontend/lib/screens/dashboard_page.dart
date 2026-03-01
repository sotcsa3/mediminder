// MediMinder – Dashboard Page

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayMeds = state.medications;
        final upcomingAppt =
            state.upcomingAppointments.isNotEmpty
                ? state.upcomingAppointments.first
                : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Today's Medications ──────────────
            _SectionCard(
              icon: '💊',
              title: 'Mai gyógyszerek',
              child: todayMeds.isEmpty
                  ? const _EmptyState(
                      icon: '🎉',
                      text: 'Nincs mai gyógyszer bejegyezve',
                    )
                  : Column(
                      children: todayMeds.expand((med) {
                        return med.times.map((time) {
                          final taken =
                              state.isMedTaken(med.id, today, time);
                          return _DashboardMedItem(
                            name: med.name,
                            dosage: med.dosage,
                            time: time,
                            taken: taken,
                            onTap: () =>
                                state.toggleMedTaken(med.id, today, time),
                          );
                        });
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // ── Next Appointment ─────────────────
            _SectionCard(
              icon: '🩺',
              title: 'Következő vizit',
              child: upcomingAppt != null
                  ? _DashboardAppointmentCard(
                      doctor: upcomingAppt.doctor,
                      specialty: upcomingAppt.specialty,
                      date: upcomingAppt.date,
                      time: upcomingAppt.time,
                      location: upcomingAppt.location,
                    )
                  : const _EmptyState(
                      icon: '📅',
                      text: 'Nincs közelgő orvosi találkozó',
                    ),
            ),
            const SizedBox(height: 16),

            // ── Stats ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    number: state.takenTodayCount.toString(),
                    label: 'Bevéve ma',
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    number: state.remainingTodayCount.toString(),
                    label: 'Még hátra',
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    number: state.weekAppointmentCount.toString(),
                    label: 'Vizit a héten',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// ── Section Card ────────────────────────────
class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryBg,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Med Item ──────────────────────
class _DashboardMedItem extends StatelessWidget {
  final String name;
  final String dosage;
  final String time;
  final bool taken;
  final VoidCallback onTap;

  const _DashboardMedItem({
    required this.name,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: taken ? AppTheme.successBg : AppTheme.bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: taken ? AppTheme.successColor : Colors.transparent,
                  border: Border.all(
                    color:
                        taken ? AppTheme.successColor : AppTheme.primaryColor,
                    width: 3,
                  ),
                ),
                child: taken
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        decoration: taken
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: taken
                            ? AppTheme.textSecondary
                            : AppTheme.textColor,
                      ),
                    ),
                    Text(
                      dosage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Time chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: taken ? AppTheme.successBg : AppTheme.primaryBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        taken ? AppTheme.successColor : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Appointment Card ──────────────
class _DashboardAppointmentCard extends StatelessWidget {
  final String doctor;
  final String specialty;
  final String date;
  final String time;
  final String location;

  const _DashboardAppointmentCard({
    required this.doctor,
    required this.specialty,
    required this.date,
    required this.time,
    required this.location,
  });

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy. MMMM d., EEEE', 'hu').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppTheme.secondaryColor, width: 5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          if (specialty.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                specialty,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('🕐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Text('📍', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────
class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _StatCard({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────
class _EmptyState extends StatelessWidget {
  final String icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
