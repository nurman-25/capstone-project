import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_models.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<http.Response> _safePost(Uri uri, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw Exception('Tidak bisa terhubung ke server API. Pastikan backend hidup di $baseUrl');
    } on TimeoutException {
      throw Exception(
        'Koneksi ke server API timeout. Pastikan backend hidup, HP/emulator satu jaringan, '
        'dan API_BASE_URL benar: $baseUrl',
      );
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    }
  }

  Future<AuthResult> register({
    required String username,
    required int storeId,
    required String role,
    required String password,
    String? email,
  }) async {
    final res = await _safePost(Uri.parse('$baseUrl/auth/register'), {
      'username': username,
      'store_id': storeId,
      'role': role,
      'password': password,
      'email': email,
    });
    if (res.statusCode >= 400) {
      throw Exception('Register gagal [${res.statusCode}]: ${res.body}');
    }
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final res = await _safePost(Uri.parse('$baseUrl/auth/login'), {
      'username': username,
      'password': password,
    });
    if (res.statusCode >= 400) {
      throw Exception('Login gagal [${res.statusCode}]: ${res.body}');
    }
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AuthResult> googleAuth({
    required String email,
    required String role,
    required int storeId,
  }) async {
    final res = await _safePost(Uri.parse('$baseUrl/auth/google'), {
      'email': email,
      'role': role,
      'store_id': storeId,
    });
    if (res.statusCode >= 400) {
      throw Exception('Google Auth gagal [${res.statusCode}]: ${res.body}');
    }
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/dashboard'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil dashboard');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getDashboardTrend() async {
    final res = await http.get(Uri.parse('$baseUrl/dashboard/trend'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil trend dashboard');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await http.get(Uri.parse('$baseUrl/history'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil history');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAdminProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/products'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil produk admin');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> updateAdminProduct({
    required int productId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/admin/products/$productId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception('Gagal update produk [${res.statusCode}]: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteAdminProduct(int productId) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/products/$productId'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal hapus produk [${res.statusCode}]: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> createAdminUser({
    required Map<String, dynamic> payload,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/admin/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception('Gagal tambah user [${res.statusCode}]: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminUser({
    required int userId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/admin/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception('Gagal update user [${res.statusCode}]: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteAdminUser(int userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/users/$userId'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal hapus user [${res.statusCode}]: ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil users admin');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getSessionDetail(int sessionId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/sessions/$sessionId'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil detail session');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminReportSummary() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/report-summary'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil ringkasan laporan');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminStores() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/stores'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal ambil store');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createAdminStore(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/admin/stores'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception('Gagal tambah store [${res.statusCode}]: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminStore({
    required int storeId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/admin/stores/$storeId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception('Gagal update store [${res.statusCode}]: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteAdminStore(int storeId) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/stores/$storeId'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal hapus store [${res.statusCode}]: ${res.body}');
    }
  }

  Future<String> exportAdminReport() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/export-report'));
    if (res.statusCode >= 400) {
      throw Exception('Gagal export laporan');
    }
    return utf8.decode(res.bodyBytes);
  }

  Future<void> saveAudit({
    int? userId,
    int? storeId,
    required String imagePath,
    required String algorithmUsed,
    required String status,
    String? sessionDate,
    Map<String, dynamic>? rawJson,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'store_id': storeId,
      'image_path': imagePath,
      'algorithm_used': algorithmUsed,
      'status': status,
      'raw_json': rawJson ?? {},
    };
    if (sessionDate != null && sessionDate.isNotEmpty) {
      payload['session_date'] = sessionDate;
    }
    final res = await _safePost(Uri.parse('$baseUrl/audit/save'), payload);
    if (res.statusCode >= 400) {
      throw Exception('Simpan audit gagal [${res.statusCode}]: ${res.body}');
    }
  }
}
