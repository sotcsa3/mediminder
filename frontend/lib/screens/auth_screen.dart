// MediMinder – Auth Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = context.read<AppState>();
      if (_isLogin) {
        await state.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await state.register(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hiba történt: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    if (code.contains('Invalid credentials') ||
        code.contains('401')) {
      return 'Hibás email vagy jelszó';
    }
    if (code.contains('already exists') || code.contains('409')) {
      return 'Ez az email cím már regisztrálva van';
    }
    if (code.contains('network') || code.contains('Hálózati')) {
      return 'Hálózati hiba – ellenőrizze az internetkapcsolatot';
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        const Text('💊',
                            style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Bejelentkezés' : 'Regisztráció',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email cím',
                            hintText: 'pelda@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Adja meg az email címét';
                            }
                            if (!val.contains('@')) {
                              return 'Érvénytelen email cím';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Jelszó',
                            hintText: 'Minimum 6 karakter',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Adja meg a jelszavát';
                            }
                            if (val.length < 6) {
                              return 'Minimum 6 karakter szükséges';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.dangerColor,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? 'Bejelentkezés'
                                        : 'Regisztráció',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Switch mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Még nincs fiókja?'
                                  : 'Már van fiókja?',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? 'Regisztráció' : 'Bejelentkezés',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'vagy',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _googleSignIn,
                            icon: Image.network(
                              'https://developers.google.com/identity/images/g-logo.png',
                              height: 22,
                              width: 22,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_mobiledata, size: 22),
                            ),
                            label: const Text(
                              'Bejelentkezés Google fiókkal',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppTheme.textColor,
                              side: const BorderSide(
                                  color: AppTheme.borderColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For now, show a message that Google Sign-In requires platform configuration
      setState(() {
        _errorMessage =
            'A Google bejelentkezés natív konfigurációt igényel. Használja az email/jelszó bejelentkezést.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
