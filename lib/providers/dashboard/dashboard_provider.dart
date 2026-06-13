import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/dashboard/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  AdminDashboardOverview? _adminOverview;
  EmployeeDashboardSummary? _employeeSummary;
  bool _isLoading = false;
  String? _error;

  AdminDashboardOverview? get adminOverview => _adminOverview;
  EmployeeDashboardSummary? get employeeSummary => _employeeSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> fetchAdminOverview(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr = _formatDate(date);
      final response = await ApiService().get('/api/dashboard-overview?date=$dateStr');
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        _adminOverview = AdminDashboardOverview.fromJson(decoded);
      } else {
        _error = 'Failed to load dashboard data: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEmployeeDashboard(int employeeId, String monthQuery) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Month query format: MM-YYYY
      final summaryResponse = await ApiService().get(
        '/api/dashboard-summary?month=$monthQuery&employee_id=$employeeId',
      );
      final chartResponse = await ApiService().get(
        '/api/dashboard-chart?month=$monthQuery&employee_id=$employeeId',
      );

      if (summaryResponse.statusCode == 200 && chartResponse.statusCode == 200) {
        final Map<String, dynamic> summaryDecoded = jsonDecode(summaryResponse.body);
        final Map<String, dynamic> chartDecoded = jsonDecode(chartResponse.body);

        final chartDataList = chartDecoded['data'] as List? ?? [];
        _employeeSummary = EmployeeDashboardSummary.fromJson(summaryDecoded, chartDataList);
      } else {
        _error = 'Failed to load dashboard data';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
