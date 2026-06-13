import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // For Android Emulator, 10.0.2.2 points to localhost of host machine.
  // For iOS Simulator / Web, use localhost or 127.0.0.1.
  String _baseUrl = 'https://api.afaqmis.com';
  String? _token;
  Function? _onSessionExpired;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  void configure({required String baseUrl, Function? onSessionExpired}) {
    _baseUrl = baseUrl;
    if (onSessionExpired != null) {
      _onSessionExpired = onSessionExpired;
    }
  }

  void setToken(String? token) {
    _token = token;
  }

  void setSessionExpiredCallback(Function callback) {
    _onSessionExpired = callback;
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      _handleSessionExpired();
      return;
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['code'] == 'token_not_valid') {
        _handleSessionExpired();
      }
    } catch (_) {}
  }

  void _handleSessionExpired() {
    if (_onSessionExpired != null) {
      _onSessionExpired!();
    }
  }

  Uri _buildUri(String path) {
    var base = _baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    var cleanPath = path;
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    return Uri.parse('$base$cleanPath');
  }

  Future<http.Response> get(String path) async {
    final url = _buildUri(path);
    try {
      final response = await http.get(url, headers: _getHeaders());
      _checkResponse(response);
      return response;
    } catch (e) {
      throw SocketException('Network error: $e');
    }
  }

  Future<http.Response> post(String path, dynamic body) async {
    final url = _buildUri(path);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await http.post(url, headers: _getHeaders(), body: encodedBody);
      _checkResponse(response);
      return response;
    } catch (e) {
      throw SocketException('Network error: $e');
    }
  }

  Future<http.Response> put(String path, dynamic body) async {
    final url = _buildUri(path);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await http.put(url, headers: _getHeaders(), body: encodedBody);
      _checkResponse(response);
      return response;
    } catch (e) {
      throw SocketException('Network error: $e');
    }
  }

  Future<http.Response> delete(String path) async {
    final url = _buildUri(path);
    try {
      final response = await http.delete(url, headers: _getHeaders());
      _checkResponse(response);
      return response;
    } catch (e) {
      throw SocketException('Network error: $e');
    }
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final url = _buildUri(path);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await http.patch(url, headers: _getHeaders(), body: encodedBody);
      _checkResponse(response);
      return response;
    } catch (e) {
      throw SocketException('Network error: $e');
    }
  }
}
