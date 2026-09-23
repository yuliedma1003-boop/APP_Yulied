import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  String baseUrl;
  String? token;

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<bool> health() async {
    try {
      final res = await http.get(_uri('/api/health')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respuesta inválida del servidor (${res.statusCode})');
    }
    if (res.statusCode >= 400 || body['ok'] == false) {
      throw ApiException(body['error']?.toString() ?? 'Error ${res.statusCode}');
    }
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http
        .post(_uri('/api/auth/login'), headers: _headers, body: jsonEncode({'email': email, 'password': password}))
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<Map<String, dynamic>> register({
    required String id,
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final res = await http
        .post(
          _uri('/api/auth/register'),
          headers: _headers,
          body: jsonEncode({'id': id, 'name': name, 'email': email, 'password': password, 'phone': phone}),
        )
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<Map<String, dynamic>> sync({String? since, required List<Map<String, dynamic>> changes}) async {
    final res = await http
        .post(
          _uri('/api/sync'),
          headers: _headers,
          body: jsonEncode({'since': since, 'changes': changes}),
        )
        .timeout(const Duration(seconds: 12));
    return _decode(res);
  }
}
