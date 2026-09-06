import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// Thin wrapper around package:http that adds the base URL, the bearer
/// token, JSON encoding/decoding, timeouts, and consistent error messages.
class ApiClient {
  String baseUrl;
  String? token;

  ApiClient({required this.baseUrl, this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _u(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode == 204) return null;
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = (body is Map && body['error'] is String) ? body['error'] as String : 'Request failed (${res.statusCode}).';
    throw ApiException(message, res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_u(path), headers: _headers).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res =
        await http.post(_u(path), headers: _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final res =
        await http.put(_u(path), headers: _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_u(path), headers: _headers).timeout(const Duration(seconds: 15));
    return _handle(res);
  }
}
