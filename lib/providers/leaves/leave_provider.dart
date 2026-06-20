import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/leaves/leave_model.dart';

class LeaveProvider extends ChangeNotifier {
  List<LeaveModel> _leaves = [];
  List<EmployeeModel> _employees = [];
  List<LeaveTypeModel> _leaveTypes = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveModel> get leaves => _leaves;
  List<EmployeeModel> get employees => _employees;
  List<LeaveTypeModel> get leaveTypes => _leaveTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaveTypes() async {
    try {
      final response = await ApiService().get('/api/leave-types?active=1');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['leave_types'] as List? ?? [];
        _leaveTypes = list.map((item) => LeaveTypeModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchLeaveTypes error: $e');
    }
  }

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

  Future<void> fetchLeaves({int? employeeId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<String> queryParams = [];
      if (employeeId != null) queryParams.add('employee_id=$employeeId');
      if (status != null && status.isNotEmpty) queryParams.add('status=$status');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await ApiService().get('/api/employee-leaves$queryString');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['leaves'] as List? ?? [];
        _leaves = list.map((item) => LeaveModel.fromJson(item)).toList();
      } else {
        _error = 'Failed to load leave records';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLeave(LeaveModel leave) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/leaves', leave.toJson());
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? decoded['error'] ?? 'Failed to save leave application';
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

  Future<bool> updateLeave(int id, LeaveModel leave) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().put('/api/leaves/$id', leave.toJson());
      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? decoded['error'] ?? 'Failed to update leave application';
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

  Future<bool> deleteLeave(int id) async {
    try {
      final response = await ApiService().delete('/api/leaves/$id');
      if (response.statusCode == 200) {
        _leaves.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('deleteLeave error: $e');
    }
    return false;
  }

  Future<bool> updateLeaveStatus(int id, String status) async {
    try {
      final response = await ApiService().patch('/api/leaves/$id/status', {
        'status': status,
      });
      if (response.statusCode == 200) {
        final index = _leaves.indexWhere((item) => item.id == id);
        if (index != -1) {
          final old = _leaves[index];
          _leaves[index] = LeaveModel(
            id: old.id,
            leaveId: old.leaveId,
            date: old.date,
            code: old.code,
            departmentId: old.departmentId,
            departmentName: old.departmentName,
            employeeId: old.employeeId,
            employeeName: old.employeeName,
            designation: old.designation,
            leaveTypeId: old.leaveTypeId,
            leaveType: old.leaveType,
            fromDate: old.fromDate,
            toDate: old.toDate,
            days: old.days,
            requestedDays: old.requestedDays,
            reason: old.reason,
            status: status,
            allowed: status == 'approved',
            pay: old.pay,
            mode: old.mode,
            leaveSource: old.leaveSource,
            createdAt: old.createdAt,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('updateLeaveStatus error: $e');
    }
    return false;
  }

  Future<String?> fetchNextLeaveId() async {
    try {
      final response = await ApiService().get('/api/leaves/leave-id');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['leave_id']?.toString();
      }
    } catch (e) {
      debugPrint('fetchNextLeaveId error: $e');
    }
    return null;
  }
}
