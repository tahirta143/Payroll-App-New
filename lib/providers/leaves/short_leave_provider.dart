import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/leaves/short_leave_model.dart';

class ShortLeaveProvider extends ChangeNotifier {
  List<ShortLeaveModel> _shortLeaves = [];
  List<EmployeeModel> _employees = [];
  bool _isLoading = false;
  String? _error;

  List<ShortLeaveModel> get shortLeaves => _shortLeaves;
  List<EmployeeModel> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEmployees() async {
    try {
      final response = await ApiService().get('/api/employees');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['employees'] as List? ?? [];
        _employees = list.map((item) => EmployeeModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchEmployees error: $e');
    }
  }

  Future<void> fetchShortLeaves({int? employeeId, String? status, String? fromDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String>[];
      if (employeeId != null) params.add('employee_id=$employeeId');
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (fromDate != null && fromDate.isNotEmpty) params.add('from_date=$fromDate');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await ApiService().get('/api/short-leaves$queryString');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['leaves'] as List? ?? [];
        _shortLeaves = list.map((item) => ShortLeaveModel.fromJson(item)).toList();
      } else {
        _error = 'Failed to load short leave records';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createShortLeave(ShortLeaveModel shortLeave) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/short-leaves', shortLeave.toJson());
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? decoded['error'] ?? 'Failed to save short leave';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShortLeave(int id, ShortLeaveModel shortLeave) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().put('/api/short-leaves/$id', shortLeave.toJson());
      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? decoded['error'] ?? 'Failed to update short leave';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShortLeave(int id) async {
    try {
      // DELETE route on backend has a trailing slash: /api/short-leaves/:id/
      final response = await ApiService().delete('/api/short-leaves/$id/');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _shortLeaves.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('deleteShortLeave error: $e');
    }
    return false;
  }

  Future<bool> updateShortLeaveStatus(int id, String status) async {
    try {
      final index = _shortLeaves.indexWhere((item) => item.id == id);
      if (index == -1) return false;
      final old = _shortLeaves[index];

      final updated = ShortLeaveModel(
        id: old.id,
        employeeId: old.employeeId,
        employeeName: old.employeeName,
        leaveDate: old.leaveDate,
        fromTime: old.fromTime,
        toTime: old.toTime,
        totalMinutes: old.totalMinutes,
        leaveType: old.leaveType,
        reason: old.reason,
        isPaid: old.isPaid,
        status: status,
      );

      final response = await ApiService().put('/api/short-leaves/$id', updated.toJson());
      if (response.statusCode == 200) {
        _shortLeaves[index] = updated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('updateShortLeaveStatus error: $e');
    }
    return false;
  }
}
