import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_services/api_service.dart';
import '../../models/auth/user_model.dart';
import '../../core/permissions.dart';

class AuthProvider extends ChangeNotifier {
  LoginResponse? _authData;
  bool _isLoading = false;
  String? _errorMessage;

  LoginResponse? get authData => _authData;
  UserModel? get user => _authData?.user;
  List<String> get permissions => _authData?.permissions ?? [];
  bool get isAuthenticated => _authData != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Register self for session expiration callbacks
    ApiService().setSessionExpiredCallback(logout);
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('auth_session');
    if (dataStr != null) {
      try {
        final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
        _authData = LoginResponse.fromJson(decoded);
        ApiService().setToken(_authData?.token);
        notifyListeners();
        
        final username = prefs.getString('saved_username');
        final password = prefs.getString('saved_password');
        if (username != null && password != null) {
          await loginInBackground(username, password);
        } else {
          await resolveCorrectEmployeeId();
        }
      } catch (e) {
        await prefs.remove('auth_session');
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
        _authData = null;
        notifyListeners();
      }
    }
  }

  Future<bool> loginInBackground(String emailOrUsername, String password) async {
    try {
      final response = await ApiService().post('/api/users/login', {
        'emailOrUsername': emailOrUsername,
        'password': password,
      });

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _authData = LoginResponse.fromJson(json);
        ApiService().setToken(_authData!.token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_session', jsonEncode(json));

        await resolveCorrectEmployeeId();
        notifyListeners();
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 400 || response.statusCode == 403) {
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('loginInBackground error: $e');
    }
    return false;
  }

  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/users/login', {
        'emailOrUsername': emailOrUsername,
        'password': password,
      });

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _authData = LoginResponse.fromJson(json);
        ApiService().setToken(_authData!.token);

        // Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_session', jsonEncode(json));
        await prefs.setString('saved_username', emailOrUsername);
        await prefs.setString('saved_password', password);

        await resolveCorrectEmployeeId();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json['message'] ?? 'Authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resolveCorrectEmployeeId() async {
    if (_authData?.user == null) return;
    final user = _authData!.user;
    
    // Skip if employeeId is null (admins or external users who aren't employees)
    if (user.employeeId == null) return;
    
    try {
      final response = await ApiService().get('/api/employees');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['employees'] as List? ?? [];
        
        final userNameLower = user.name.toLowerCase().trim();
        final userUsernameLower = user.username.toLowerCase().trim();
        
        int? matchedId;
        int? matchedDeptId;
        
        // Exact matches first
        for (var item in list) {
          final empName = (item['name']?.toString() ?? '').toLowerCase().trim();
          final empCode = (item['emp_id']?.toString() ?? '').toLowerCase().trim();
          
          if (empName == userNameLower || empCode == userUsernameLower) {
            matchedId = item['id'] as int?;
            matchedDeptId = item['department_id'] as int?;
            break;
          }
        }
        
        // If no exact match, try fuzzy matching name or username
        if (matchedId == null) {
          for (var item in list) {
            final empName = (item['name']?.toString() ?? '').toLowerCase().trim();
            
            if (empName.contains(userUsernameLower) || 
                userUsernameLower.contains(empName) ||
                empName.contains(userNameLower) ||
                userNameLower.contains(empName)) {
              matchedId = item['id'] as int?;
              matchedDeptId = item['department_id'] as int?;
              break;
            }
          }
        }
        
        if (matchedId != null && matchedId != user.employeeId) {
          debugPrint('Resolved mismatched employee ID for ${user.username}: ${user.employeeId} -> $matchedId');
          final updatedUser = user.copyWith(
            employeeId: matchedId,
            departmentId: matchedDeptId ?? user.departmentId,
          );
          _authData = _authData!.copyWith(user: updatedUser);
          
          // Re-save session locally with resolved ID
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_session', jsonEncode(_authData!.toJson()));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('resolveCorrectEmployeeId error: $e');
    }
  }

  Future<void> logout() async {
    _authData = null;
    ApiService().setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_session');
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    notifyListeners();
  }

  bool hasPermission(String code) {
    return AppPermissions.hasPermission(permissions, code);
  }

  bool hasAnyPermission(List<String> codes) {
    return AppPermissions.hasAnyPermission(permissions, codes);
  }
}
