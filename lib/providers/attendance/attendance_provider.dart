import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceModel> _attendanceList = [];
  List<DepartmentModel> _departments = [];
  List<DutyShiftModel> _dutyShifts = [];
  List<EmployeeModel> _employees = []; // Dynamic employee selector options
  List<EmployeeModel> _filterEmployees = []; // Used for general filter list
  bool _isLoading = false;
  String? _error;

  List<AttendanceModel> get attendanceList => _attendanceList;
  List<DepartmentModel> get departments => _departments;
  List<DutyShiftModel> get dutyShifts => _dutyShifts;
  List<EmployeeModel> get employees => _employees;
  List<EmployeeModel> get filterEmployees => _filterEmployees;
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

  Future<void> fetchDutyShifts() async {
    try {
      final response = await ApiService().get('/api/duty-shifts');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['duty_shifts'] as List? ?? [];
        _dutyShifts = list.map((item) => DutyShiftModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchDutyShifts error: $e');
    }
  }

  Future<void> fetchAllEmployees() async {
    try {
      final response = await ApiService().get('/api/employees');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['employees'] as List? ?? [];
        _filterEmployees = list.map((item) => EmployeeModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchAllEmployees error: $e');
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

  Future<void> fetchAttendance({
    int? departmentId,
    int? employeeId,
    int? dutyShiftId,
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<String> params = [];
      if (departmentId != null) params.add('department_id=$departmentId');
      if (employeeId != null) params.add('employee_id=$employeeId');
      if (dutyShiftId != null) params.add('duty_shift_id=$dutyShiftId');
      if (dateFrom != null) params.add('date_from=$dateFrom');
      if (dateTo != null) params.add('date_to=$dateTo');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await ApiService().get('/api/attendance$queryString');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['attendance'] as List? ?? [];
        _attendanceList = list.map((item) => AttendanceModel.fromJson(item)).toList();
      } else {
        _error = 'Failed to load attendance records';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAttendance({
    required String date,
    required int departmentId,
    required int employeeId,
    required int? dutyShiftId,
    String? machineCode,
    String? dutyShiftText,
    String? timeIn,
    String? timeOut,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/attendance', {
        'date': date,
        'department_id': departmentId,
        'employee_id': employeeId,
        'duty_shift_id': dutyShiftId,
        'machine_code': machineCode,
        'duty_shift': dutyShiftText,
        'time_in': timeIn,
        'time_out': timeOut,
      });

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to save attendance';
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

  Future<bool> updateAttendance({
    required int id,
    required String date,
    required int departmentId,
    required int employeeId,
    required int? dutyShiftId,
    String? machineCode,
    String? dutyShiftText,
    String? timeIn,
    String? timeOut,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().put('/api/attendance/$id/', {
        'date': date,
        'department_id': departmentId,
        'employee_id': employeeId,
        'duty_shift_id': dutyShiftId,
        'machine_code': machineCode,
        'duty_shift': dutyShiftText,
        'time_in': timeIn,
        'time_out': timeOut,
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to update attendance';
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

  Future<bool> deleteAttendance(int id) async {
    try {
      final response = await ApiService().delete('/api/attendance/$id/');
      if (response.statusCode == 200) {
        _attendanceList.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('deleteAttendance error: $e');
    }
    return false;
  }
}
