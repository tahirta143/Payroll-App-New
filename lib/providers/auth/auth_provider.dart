import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
        _setupFcm();
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
        _setupFcm();
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
    await _cleanupFcm();
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

  // Setup FCM for the logged-in user
  Future<void> _setupFcm() async {
    if (kIsWeb || Firebase.apps.isEmpty) {
      debugPrint('FCM setup skipped (running on Web or Firebase not initialized).');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted notification permissions.');

        // 2. Retrieve FCM Token
        String? fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          debugPrint('FCM Token: $fcmToken');
          // Register token to backend
          try {
            final response = await ApiService().registerFcmToken(fcmToken);
            debugPrint('FCM Token registration response code: ${response.statusCode}');
            debugPrint('FCM Token registration response body: ${response.body}');
          } catch (e) {
            debugPrint('FCM Token registration HTTP request failed: $e');
          }
        }

        // 3. Listen to token refreshes
        messaging.onTokenRefresh.listen((token) async {
          debugPrint('FCM Token Refreshed: $token');
          if (isAuthenticated) {
            try {
              final response = await ApiService().registerFcmToken(token);
              debugPrint('FCM Refreshed Token registration response code: ${response.statusCode}');
            } catch (e) {
              debugPrint('FCM Refreshed Token registration failed: $e');
            }
          }
        });
      } else {
        debugPrint('User declined or has not accepted notification permissions.');
      }
    } catch (e) {
      debugPrint('Error setting up FCM: $e');
    }
  }

  // Clean up FCM on logout
  Future<void> _cleanupFcm() async {
    if (kIsWeb || Firebase.apps.isEmpty) return;
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService().deleteFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error cleaning up FCM token: $e');
    }
  }

  // --- Password Reset OTP Flow Helpers ---

  Future<Map<String, dynamic>> forgotPassword(String usernameOrEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/users/forgot-password', {
        'usernameOrEmail': usernameOrEmail,
      });

      final json = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'OTP sent successfully',
          'maskedEmail': json['maskedEmail'] ?? '',
        };
      } else {
        _errorMessage = json['message'] ?? 'Failed to request OTP';
        return {'success': false, 'message': _errorMessage!};
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage!};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String usernameOrEmail, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/users/verify-otp', {
        'usernameOrEmail': usernameOrEmail,
        'otp': otp,
      });

      final json = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'OTP verified successfully',
          'userId': json['userId'],
        };
      } else {
        _errorMessage = json['message'] ?? 'OTP verification failed';
        return {'success': false, 'message': _errorMessage!};
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage!};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp(int userId, String newPassword, String confirmPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/users/reset-password-otp', {
        'userId': userId,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });

      final json = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'Password reset successfully',
        };
      } else {
        _errorMessage = json['message'] ?? 'Failed to reset password';
        return {'success': false, 'message': _errorMessage!};
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage!};
    }
  }
}
