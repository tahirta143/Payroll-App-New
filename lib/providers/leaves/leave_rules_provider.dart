import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_services/api_service.dart';
import '../../models/leaves/leave_rules_model.dart';

class LeaveRulesProvider extends ChangeNotifier {
  LeaveRulesModel _leaveRules = LeaveRulesModel();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _hasLeaveRules = false;

  bool _isInitialized = false;

  LeaveRulesModel get leaveRules => _leaveRules;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasLeaveRules => _hasLeaveRules;
  bool get isInitialized => _isInitialized;

  // Update a single field in the leave rules model locally
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'casual_leave_per_year':
        _leaveRules.casualLeavePerYear = value as int;
        break;
      case 'sandwich_before_and_after':
        _leaveRules.sandwichBeforeAndAfter = value as bool;
        break;
      case 'sandwich_before_only':
        _leaveRules.sandwichBeforeOnly = value as bool;
        break;
      case 'sandwich_after_only':
        _leaveRules.sandwichAfterOnly = value as bool;
        break;
      case 'late_grace_minutes':
        _leaveRules.lateGraceMinutes = value as int;
        break;
      case 'late_partial_max_minutes':
        _leaveRules.latePartialMaxMinutes = value as int;
        break;
      case 'short_leave_max_hours':
        _leaveRules.shortLeaveMaxHours = (value as num).toDouble();
        break;
      case 'short_leaves_per_casual':
        _leaveRules.shortLeavesPerCasual = value as int;
        break;
      case 'half_day_min_minutes':
        _leaveRules.halfDayMinMinutes = value as int;
        break;
      case 'half_days_per_casual':
        _leaveRules.halfDaysPerCasual = value as int;
        break;
      case 'early_dispersal_threshold_minutes':
        _leaveRules.earlyDispersalThresholdMinutes = value as int;
        break;
      case 'short_leaves_per_deduction':
        _leaveRules.shortLeavesPerDeduction = value as int;
        break;
      case 'half_days_per_deduction':
        _leaveRules.halfDaysPerDeduction = value as int;
        break;
      case 'late_grace_per_deduction':
        _leaveRules.lateGracePerDeduction = value as int;
        break;
      case 'late_partial_per_deduction':
        _leaveRules.latePartialPerDeduction = value as int;
        break;
      case 'allowance_late_grace':
        _leaveRules.allowanceLateGrace = value as int;
        break;
      case 'allowance_late_partial':
        _leaveRules.allowanceLatePartial = value as int;
        break;
      case 'allowance_half_day':
        _leaveRules.allowanceHalfDay = value as int;
        break;
      case 'allowance_short_leave':
        _leaveRules.allowanceShortLeave = value as int;
        break;
      case 'allowance_day_leave':
        _leaveRules.allowanceDayLeave = value as int;
        break;
      case 'advance_approval_required':
        _leaveRules.advanceApprovalRequired = value as bool;
        break;
      case 'unauthorized_absence_deduction':
        _leaveRules.unauthorizedAbsenceDeduction = value as String;
        break;
    }
    notifyListeners();
  }

  Future<void> fetchLeaveRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/api/attendance-settings');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final settings = decoded['settings'];
        if (settings != null && settings['casual_leave_per_year'] != null) {
          _leaveRules = LeaveRulesModel.fromJson(settings);
          _hasLeaveRules = true;
        } else {
          _leaveRules = LeaveRulesModel(); // Defaults
          _hasLeaveRules = false;
        }
        _isInitialized = true;
      } else {
        _error = 'Failed to load settings (Status Code: ${response.statusCode})';
        _isInitialized = false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveLeaveRules() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/api/attendance-settings',
        _leaveRules.toJson(),
      );

      _isSaving = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _hasLeaveRules = true;
        _isInitialized = true;
        notifyListeners();
        return true;
      } else {
        final decoded = jsonDecode(response.body);
        _error = decoded['message'] ?? 'Failed to save leave rules';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void resetToDefaults() {
    _leaveRules = LeaveRulesModel();
    _hasLeaveRules = false;
    notifyListeners();
  }
}
