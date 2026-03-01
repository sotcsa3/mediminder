// MediMinder – API Configuration

class ApiConfig {
  // Base URL - defaults based on platform
  static const String defaultBaseUrl = 'http://localhost:8080/api/v1';
  static const String productionBaseUrl = '/api/v1';

  // Google OAuth
  static const String googleClientId =
      '82374151917-ari80p75dqshq1hs9idjf9sm9efl4pdl.apps.googleusercontent.com';

  // Timeouts
  static const Duration timeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  // Storage keys
  static const String tokenKey = 'mediminder_token';
  static const String medicationsKey = 'mediminder_medications';
  static const String medLogsKey = 'mediminder_med_logs';
  static const String appointmentsKey = 'mediminder_appointments';
  static const String userKey = 'mediminder_user';
  static const String notifEnabledKey = 'mediminder_notif_enabled';
  static const String notifSentKey = 'mediminder_notif_sent';

  // Admin
  static const String adminEmail = 'sotcsa+admin@gmail.com';

  // App version
  static const String appVersion = '3.0.0';
}
