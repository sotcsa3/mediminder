// MediMinder – Main Entry Point

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hu', null);

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MediMinderApp(),
    ),
  );
}

class MediMinderApp extends StatelessWidget {
  const MediMinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediMinder',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showingSplash = true;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // Check existing session
    final state = context.read<AppState>();
    await state.checkExistingSession();

    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showingSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingSplash) {
      return const SplashScreen();
    }

    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoggedIn) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
