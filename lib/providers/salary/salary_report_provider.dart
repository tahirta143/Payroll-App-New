import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/salary/salary_report_model.dart';

class SalaryReportProvider extends ChangeNotifier {
  List<DepartmentModel> _departments = [];
  List<EmployeeModel> _employees = [];
  
  MonthlySalarySheetResponse? _salarySheet;
  SalarySlipResponse? _salarySlip;
  
  bool _isLoading = false;
  String? _error;

  List<DepartmentModel> get departments => _departments;
  List<EmployeeModel> get employees => _employees;
  MonthlySalarySheetResponse? get salarySheet => _salarySheet;
  SalarySlipResponse? get salarySlip => _salarySlip;
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

  Future<void> fetchMonthlySalarySheet({required String month, int? departmentId}) async {
    _isLoading = true;
    _error = null;
    _salarySheet = null;
    notifyListeners();

    try {
      String path = '/api/monthly-salary-sheet?month=$month';
      if (departmentId != null) {
        path += '&department_id=$departmentId';
      }
      final response = await ApiService().get(path);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _salarySheet = MonthlySalarySheetResponse.fromJson(decoded);
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to load Monthly Salary Sheet';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalarySlip({required String month, required int employeeId}) async {
    _isLoading = true;
    _error = null;
    _salarySlip = null;
    notifyListeners();

    try {
      final path = '/api/salary-slip?month=$month&employee_id=$employeeId';
      final response = await ApiService().get(path);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _salarySlip = SalarySlipResponse.fromJson(decoded);
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to load Salary Slip';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
