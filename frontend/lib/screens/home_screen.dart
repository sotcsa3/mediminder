// MediMinder – Home Screen (with Bottom Navigation)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/api_config.dart';
import 'dashboard_page.dart';
import 'medications_page.dart';
import 'appointments_page.dart';
import 'admin_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Jó reggelt! ☀️';
    if (hour < 18) return 'Jó napot! 🌤️';
    return 'Jó estét! 🌙';
  }

  String _getDateStr() {
    return DateFormat('yyyy. MMMM d., EEEE', 'hu').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final userName = state.currentUser?.name ?? 'Kedves Felhasználó';

    final pages = <Widget>[
      const DashboardPage(),
      const MedicationsPage(),
      const AppointmentsPage(),
      if (state.isAdmin) const AdminPage(),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Text('🏠', style: TextStyle(fontSize: 24)),
        activeIcon: Text('🏠', style: TextStyle(fontSize: 28)),
        label: 'Főoldal',
      ),
      const BottomNavigationBarItem(
        icon: Text('💊', style: TextStyle(fontSize: 24)),
        activeIcon: Text('💊', style: TextStyle(fontSize: 28)),
        label: 'Gyógyszerek',
      ),
      const BottomNavigationBarItem(
        icon: Text('🩺', style: TextStyle(fontSize: 24)),
        activeIcon: Text('🩺', style: TextStyle(fontSize: 28)),
        label: 'Orvos',
      ),
      if (state.isAdmin)
        const BottomNavigationBarItem(
          icon: Text('🔧', style: TextStyle(fontSize: 24)),
          activeIcon: Text('🔧', style: TextStyle(fontSize: 28)),
          label: 'Admin',
        ),
    ];

    // Clamp index if admin tab goes away
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Custom Header ──────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    // Left: Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()} $userName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDateStr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Account button
                    InkWell(
                      onTap: () => _showAccountDialog(context, state),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text('👤',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Page Content ──────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),

          // ── Version ───────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'v${ApiConfig.appVersion}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }

  void _showAccountDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👤', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            Text(
              state.currentUser?.name ?? 'Felhasználó',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 5,
                    backgroundColor: AppTheme.successColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Szinkronizálva',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bezárás'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Kijelentkezés'),
          ),
        ],
      ),
    );
  }
}
