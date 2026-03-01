// MediMinder – API Service (REST Client)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  String _baseUrl = ApiConfig.defaultBaseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;

  // ── Token Management ──────────────────────
  Future<String?> getToken() async {
    return await _storage.read(key: ApiConfig.tokenKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: ApiConfig.tokenKey, value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: ApiConfig.tokenKey);
  }

  // ── HTTP Helpers ──────────────────────────
  Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final token = await getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await http
              .post(url, headers: headers, body: jsonEncode(body))
              .timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: headers, body: jsonEncode(body))
              .timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'error': 'Request failed'};
        throw ApiException(
          errorBody['error'] ?? 'HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Hálózati hiba: $e', 0);
    }
  }

  Future<dynamic> get(String endpoint) => request(endpoint);

  Future<dynamic> post(String endpoint, dynamic data) =>
      request(endpoint, method: 'POST', body: data is Map<String, dynamic> ? data : null);

  Future<dynamic> postList(String endpoint, List<dynamic> data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http
        .post(url, headers: headers, body: jsonEncode(data))
        .timeout(ApiConfig.timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException('HTTP ${response.statusCode}', response.statusCode);
    }
  }

  Future<dynamic> delete(String endpoint) =>
      request(endpoint, method: 'DELETE');

  // ── Authentication ────────────────────────
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response =
        await post('/auth/register', {'email': email, 'password': password});
    if (response != null && response['token'] != null) {
      await setToken(response['token']);
    }
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response =
        await post('/auth/login', {'email': email, 'password': password});
    if (response != null && response['token'] != null) {
      await setToken(response['token']);
    }
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> googleLogin(String credential) async {
    final response =
        await post('/auth/google', {'credential': credential});
    if (response != null && response['token'] != null) {
      await setToken(response['token']);
    }
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final response = await get('/auth/me');
    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  Future<void> logout() async {
    await removeToken();
  }

  // ── Medications ───────────────────────────
  Future<List<dynamic>> getMedications() async {
    final response = await get('/medications');
    return response is List ? response : [];
  }

  Future<void> saveMedications(List<Map<String, dynamic>> medications) async {
    await postList('/medications', medications);
  }

  Future<void> deleteAllMedications() async {
    await delete('/medications');
  }

  // ── Medication Logs ───────────────────────
  Future<List<dynamic>> getMedLogs() async {
    final response = await get('/med-logs');
    return response is List ? response : [];
  }

  Future<void> saveMedLogs(List<Map<String, dynamic>> logs) async {
    await postList('/med-logs', logs);
  }

  Future<void> deleteAllMedLogs() async {
    await delete('/med-logs');
  }

  // ── Appointments ──────────────────────────
  Future<List<dynamic>> getAppointments() async {
    final response = await get('/appointments');
    return response is List ? response : [];
  }

  Future<void> saveAppointments(
      List<Map<String, dynamic>> appointments) async {
    await postList('/appointments', appointments);
  }

  Future<void> deleteAllAppointments() async {
    await delete('/appointments');
  }

  // ── Health Check ──────────────────────────
  Future<Map<String, dynamic>?> healthCheck() async {
    final response = await get('/health');
    return response != null ? Map<String, dynamic>.from(response) : null;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
