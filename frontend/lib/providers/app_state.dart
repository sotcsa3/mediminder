// MediMinder – App State Provider (ChangeNotifier)

import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/api_config.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DbService _db = DbService();

  AppUser? _currentUser;
  List<Medication> _medications = [];
  Map<String, dynamic> _medLogs = {};
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  bool _isOnline = true;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin =>
      _currentUser?.email == ApiConfig.adminEmail;
  List<Medication> get medications => _medications;
  Map<String, dynamic> get medLogs => _medLogs;
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  // Initialize
  Future<void> init() async {
    await _db.init();
  }

  void setOnline(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────
  Future<bool> checkExistingSession() async {
    final token = await _api.getToken();
    if (token == null) return false;

    try {
      final userData = await _api.getCurrentUser();
      if (userData != null) {
        _currentUser = AppUser.fromJson(userData);
        _db.saveUser(_currentUser!);
        await _db.onLogin(_currentUser!.id);
        _loadLocalData();
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Token invalid
      await _api.removeToken();
    }
    return false;
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.login(email, password);
      _currentUser = AppUser.fromJson(response);
      _db.saveUser(_currentUser!);
      await _db.onLogin(_currentUser!.id);
      _loadLocalData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.register(email, password);
      _currentUser = AppUser.fromJson(response);
      _db.saveUser(_currentUser!);
      await _db.onLogin(_currentUser!.id);
      _loadLocalData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle(String credential) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.googleLogin(credential);
      _currentUser = AppUser.fromJson(response);
      _db.saveUser(_currentUser!);
      await _db.onLogin(_currentUser!.id);
      _loadLocalData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _db.onLogout();
    _currentUser = null;
    _medications = [];
    _medLogs = {};
    _appointments = [];
    notifyListeners();
  }

  // ── Data Loading ──────────────────────────
  void _loadLocalData() {
    _medications = _db.getMedications();
    _medLogs = _db.getMedLogs();
    _appointments = _db.getAppointments();
  }

  Future<void> refreshData() async {
    if (_currentUser != null) {
      await _db.onLogin(_currentUser!.id);
      _loadLocalData();
      notifyListeners();
    }
  }

  // ── Medications ───────────────────────────
  Future<void> addMedication(Medication med) async {
    _medications.add(med);
    await _db.saveMedications(_medications);
    notifyListeners();
  }

  Future<void> updateMedication(Medication med) async {
    final index = _medications.indexWhere((m) => m.id == med.id);
    if (index != -1) {
      _medications[index] = med;
      await _db.saveMedications(_medications);
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
    await _db.saveMedications(_medications);
    notifyListeners();
  }

  // ── Medication Logs ───────────────────────
  String getMedLogKey(String medId, String date, String time) {
    return '${medId}_${date}_$time';
  }

  bool isMedTaken(String medId, String date, String time) {
    final key = getMedLogKey(medId, date, time);
    return _medLogs[key] != null;
  }

  Future<void> toggleMedTaken(String medId, String date, String time) async {
    final key = getMedLogKey(medId, date, time);
    if (_medLogs.containsKey(key)) {
      _medLogs.remove(key);
    } else {
      _medLogs[key] = {
        'key': key,
        'medId': medId,
        'date': date,
        'time': time,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    await _db.saveMedLogs(_medLogs);
    notifyListeners();
  }

  Future<void> markAllTimesToday(String medId) async {
    final med = _medications.firstWhere(
      (m) => m.id == medId,
      orElse: () => throw Exception('Medication not found'),
    );
    final today = _todayStr();
    for (final time in med.times) {
      final key = getMedLogKey(medId, today, time);
      if (!_medLogs.containsKey(key)) {
        _medLogs[key] = {
          'key': key,
          'medId': medId,
          'date': today,
          'time': time,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    }
    await _db.saveMedLogs(_medLogs);
    notifyListeners();
  }

  bool areMedAllTimesTakenToday(String medId) {
    final med = _medications.where((m) => m.id == medId).firstOrNull;
    if (med == null) return false;
    final today = _todayStr();
    return med.times.every((t) => isMedTaken(medId, today, t));
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Appointments ──────────────────────────
  Future<void> addAppointment(Appointment appt) async {
    _appointments.add(appt);
    await _db.saveAppointments(_appointments);
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment appt) async {
    final index = _appointments.indexWhere((a) => a.id == appt.id);
    if (index != -1) {
      _appointments[index] = appt;
      await _db.saveAppointments(_appointments);
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    await _db.saveAppointments(_appointments);
    notifyListeners();
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => a.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  // ── Stats ─────────────────────────────────
  int get takenTodayCount {
    final today = _todayStr();
    return _medLogs.keys.where((k) => k.contains(today)).length;
  }

  int get remainingTodayCount {
    final today = _todayStr();
    int total = 0;
    for (final med in _medications) {
      for (final time in med.times) {
        if (!isMedTaken(med.id, today, time)) {
          total++;
        }
      }
    }
    return total;
  }

  int get weekAppointmentCount {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _appointments.where((a) {
      final dt = a.dateTime;
      return dt.isAfter(weekStart) && dt.isBefore(weekEnd);
    }).length;
  }
}
