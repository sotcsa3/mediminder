// MediMinder – Admin Page

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.isAdmin) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔒', style: TextStyle(fontSize: 50)),
            SizedBox(height: 12),
            Text(
              'Nincs hozzáférése az admin panelhez',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // TODO: Implement actual admin API endpoints
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const Text('👥', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Text(
                        'Felhasználók',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Admin API még nem implementált a backendben'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Column(
                    children: [
                      Text('👥', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text(
                        'Az admin API a backendben még nem elérhető',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
