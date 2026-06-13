import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/salary/salary_model.dart';

class SalaryProvider extends ChangeNotifier {
  List<SalaryModel> _salaries = [];
  List<EmployeeModel> _employees = [];
  bool _isLoading = false;
  String? _error;

  List<SalaryModel> get salaries => _salaries;
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

  Future<void> fetchSalaries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/employee-salaries');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['employee_salaries'] as List? ?? [];
        _salaries = list.map((item) => SalaryModel.fromJson(item)).toList();
      } else {
        _error = 'Failed to load salary records';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSalary(SalaryModel salary) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().post('/api/employee-salaries', salary.toJson());
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to save salary';
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

  Future<bool> updateSalary(int id, SalaryModel salary) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().put('/api/employee-salaries/$id', salary.toJson());
      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to update salary';
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

  Future<bool> deleteSalary(int id) async {
    try {
      final response = await ApiService().delete('/api/employee-salaries/$id/');
      if (response.statusCode == 200) {
        _salaries.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('deleteSalary error: $e');
    }
    return false;
  }
}
