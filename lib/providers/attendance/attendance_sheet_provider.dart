import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/attendance/attendance_sheet_model.dart';

class AttendanceSheetProvider extends ChangeNotifier {
  List<DepartmentModel> _departments = [];
  List<EmployeeModel> _employees = [];
  MonthlyAttendanceSheetResponse? _attendanceSheet;

  bool _isLoading = false;
  String? _error;

  List<DepartmentModel> get departments => _departments;
  List<EmployeeModel> get employees => _employees;
  MonthlyAttendanceSheetResponse? get attendanceSheet => _attendanceSheet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDepartments() async {
    try {
      final response = await ApiService().get('/api/departments');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['departments'] as List? ?? [];
        _departments = list.map((item) => DepartmentModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchDepartments error: $e');
    }
  }

  Future<void> fetchEmployeesForDepartment(int? departmentId) async {
    if (departmentId == null) {
      _employees = [];
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get('/api/employees?department_id=$departmentId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['employees'] as List? ?? [];
        _employees = list.map((item) => EmployeeModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchEmployeesForDepartment error: $e');
    }
  }

  Future<void> fetchAttendanceSheet({
    required String month,
    String filterType = 'all',
    int? departmentId,
    int? employeeId,
  }) async {
    _isLoading = true;
    _error = null;
    _attendanceSheet = null;
    notifyListeners();

    try {
      String path = '/api/monthly-attendance-sheet?month=$month';
      if (filterType == 'employee' && employeeId != null) {
        path += '&employee_id=$employeeId';
      } else if (filterType == 'department' && departmentId != null) {
        path += '&department_id=$departmentId';
      }

      final response = await ApiService().get(path);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _attendanceSheet = MonthlyAttendanceSheetResponse.fromJson(decoded);
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to load Monthly Attendance Sheet';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
