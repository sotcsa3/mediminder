// MediMinder – Local Database / Cache Service

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_service.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/user.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  final ApiService _api = ApiService();
  SharedPreferences? _prefs;
  String? _userId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;

  // ── Local cache helpers ──────────────────
  List<Map<String, dynamic>> _localGetList(String key) {
    final data = _prefs?.getString(key);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  void _localSet(String key, dynamic value) {
    _prefs?.setString(key, jsonEncode(value));
  }

  // ── Backend sync helpers ──────────────────
  Future<List<Map<String, dynamic>>> _loadFromBackend(
      String endpoint, String localKey) async {
    if (_userId == null) return [];
    try {
      final data = await _api.get(endpoint);
      final list = (data as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      _localSet(localKey, list);
      return list;
    } catch (e) {
      return _localGetList(localKey);
    }
  }

  Future<void> _saveToBackend(String endpoint, List<Map<String, dynamic>> items) async {
    if (_userId == null) return;
    try {
      await _api.postList(endpoint, items);
    } catch (e) {
      // Offline: data persisted locally, will sync later
    }
  }

  // ── Auth lifecycle ────────────────────────
  Future<void> onLogin(String userId) async {
    _userId = userId;

    await Future.wait([
      _loadFromBackend('/medications', ApiConfig.medicationsKey),
      _loadFromBackend('/med-logs', ApiConfig.medLogsKey),
      _loadFromBackend('/appointments', ApiConfig.appointmentsKey),
    ]);
  }

  Future<void> onLogout() async {
    _userId = null;
    await _api.logout();
    _localSet(ApiConfig.medicationsKey, []);
    _localSet(ApiConfig.medLogsKey, []);
    _localSet(ApiConfig.appointmentsKey, []);
    _localSet(ApiConfig.userKey, null);
  }

  // ── Medications ───────────────────────────
  List<Medication> getMedications() {
    return _localGetList(ApiConfig.medicationsKey)
        .map((e) => Medication.fromJson(e))
        .toList();
  }

  Future<void> saveMedications(List<Medication> meds) async {
    final data = meds.map((m) => m.toJson()).toList();
    _localSet(ApiConfig.medicationsKey, data);
    if (_userId != null) {
      await _saveToBackend('/medications', data);
    }
  }

  // ── Medication Logs ───────────────────────
  Map<String, dynamic> getMedLogs() {
    final data = _prefs?.getString(ApiConfig.medLogsKey);
    if (data == null) return {};
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is List) {
        // Convert list format to map format
        final map = <String, dynamic>{};
        for (final item in decoded) {
          if (item is Map && item['key'] != null) {
            map[item['key']] = item;
          }
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveMedLogs(Map<String, dynamic> logs) async {
    _localSet(ApiConfig.medLogsKey, logs);
    if (_userId != null) {
      await _saveToBackend('/med-logs', [logs]);
    }
  }

  // ── Appointments ──────────────────────────
  List<Appointment> getAppointments() {
    return _localGetList(ApiConfig.appointmentsKey)
        .map((e) => Appointment.fromJson(e))
        .toList();
  }

  Future<void> saveAppointments(List<Appointment> appts) async {
    final data = appts.map((a) => a.toJson()).toList();
    _localSet(ApiConfig.appointmentsKey, data);
    if (_userId != null) {
      await _saveToBackend('/appointments', data);
    }
  }

  // ── User ──────────────────────────────────
  AppUser getUser() {
    final data = _prefs?.getString(ApiConfig.userKey);
    if (data == null) {
      return AppUser(id: '', email: '', name: 'Kedves Felhasználó');
    }
    try {
      return AppUser.fromJson(jsonDecode(data));
    } catch (_) {
      return AppUser(id: '', email: '', name: 'Kedves Felhasználó');
    }
  }

  void saveUser(AppUser user) {
    _localSet(ApiConfig.userKey, user.toJson());
  }
}
