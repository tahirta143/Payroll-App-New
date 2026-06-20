class LeaveRulesModel {
  int casualLeavePerYear;
  bool sandwichBeforeAndAfter;
  bool sandwichBeforeOnly;
  bool sandwichAfterOnly;
  int lateGraceMinutes;
  int latePartialMaxMinutes;
  double shortLeaveMaxHours;
  int shortLeavesPerCasual;
  int halfDayMinMinutes;
  int halfDaysPerCasual;
  int earlyDispersalThresholdMinutes;
  int shortLeavesPerDeduction;
  int halfDaysPerDeduction;
  int lateGracePerDeduction;
  int latePartialPerDeduction;
  int allowanceLateGrace;
  int allowanceLatePartial;
  int allowanceHalfDay;
  int allowanceShortLeave;
  int allowanceDayLeave;
  bool advanceApprovalRequired;
  String unauthorizedAbsenceDeduction;

  LeaveRulesModel({
    this.casualLeavePerYear = 10,
    this.sandwichBeforeAndAfter = true,
    this.sandwichBeforeOnly = true,
    this.sandwichAfterOnly = true,
    this.lateGraceMinutes = 15,
    this.latePartialMaxMinutes = 120,
    this.shortLeaveMaxHours = 2.0,
    this.shortLeavesPerCasual = 3,
    this.halfDayMinMinutes = 120,
    this.halfDaysPerCasual = 2,
    this.earlyDispersalThresholdMinutes = 420,
    this.shortLeavesPerDeduction = 3,
    this.halfDaysPerDeduction = 2,
    this.lateGracePerDeduction = 3,
    this.latePartialPerDeduction = 2,
    this.allowanceLateGrace = 2,
    this.allowanceLatePartial = 1,
    this.allowanceHalfDay = 1,
    this.allowanceShortLeave = 2,
    this.allowanceDayLeave = 1,
    this.advanceApprovalRequired = true,
    this.unauthorizedAbsenceDeduction = 'full_day',
  });

  factory LeaveRulesModel.fromJson(Map<String, dynamic> json) {
    return LeaveRulesModel(
      casualLeavePerYear: json['casual_leave_per_year'] ?? 10,
      sandwichBeforeAndAfter: json['sandwich_before_and_after'] is int
          ? json['sandwich_before_and_after'] == 1
          : (json['sandwich_before_and_after'] ?? true),
      sandwichBeforeOnly: json['sandwich_before_only'] is int
          ? json['sandwich_before_only'] == 1
          : (json['sandwich_before_only'] ?? true),
      sandwichAfterOnly: json['sandwich_after_only'] is int
          ? json['sandwich_after_only'] == 1
          : (json['sandwich_after_only'] ?? true),
      lateGraceMinutes: json['late_grace_minutes'] ?? 15,
      latePartialMaxMinutes: json['late_partial_max_minutes'] ?? 120,
      shortLeaveMaxHours: (json['short_leave_max_hours'] ?? 2.0).toDouble(),
      shortLeavesPerCasual: json['short_leaves_per_casual'] ?? 3,
      halfDayMinMinutes: json['half_day_min_minutes'] ?? 120,
      halfDaysPerCasual: json['half_days_per_casual'] ?? 2,
      earlyDispersalThresholdMinutes: json['early_dispersal_threshold_minutes'] ?? 420,
      shortLeavesPerDeduction: json['short_leaves_per_deduction'] ?? 3,
      halfDaysPerDeduction: json['half_days_per_deduction'] ?? 2,
      lateGracePerDeduction: json['late_grace_per_deduction'] ?? 3,
      latePartialPerDeduction: json['late_partial_per_deduction'] ?? 2,
      allowanceLateGrace: json['allowance_late_grace'] ?? 2,
      allowanceLatePartial: json['allowance_late_partial'] ?? 1,
      allowanceHalfDay: json['allowance_half_day'] ?? 1,
      allowanceShortLeave: json['allowance_short_leave'] ?? 2,
      allowanceDayLeave: json['allowance_day_leave'] ?? 1,
      advanceApprovalRequired: json['advance_approval_required'] is int
          ? json['advance_approval_required'] == 1
          : (json['advance_approval_required'] ?? true),
      unauthorizedAbsenceDeduction: json['unauthorized_absence_deduction'] ?? 'full_day',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casual_leave_per_year': casualLeavePerYear,
      'sandwich_before_and_after': sandwichBeforeAndAfter,
      'sandwich_before_only': sandwichBeforeOnly,
      'sandwich_after_only': sandwichAfterOnly,
      'late_grace_minutes': lateGraceMinutes,
      'late_partial_max_minutes': latePartialMaxMinutes,
      'short_leave_max_hours': shortLeaveMaxHours,
      'short_leaves_per_casual': shortLeavesPerCasual,
      'half_day_min_minutes': halfDayMinMinutes,
      'half_days_per_casual': halfDaysPerCasual,
      'early_dispersal_threshold_minutes': earlyDispersalThresholdMinutes,
      'short_leaves_per_deduction': shortLeavesPerDeduction,
      'half_days_per_deduction': halfDaysPerDeduction,
      'late_grace_per_deduction': lateGracePerDeduction,
      'late_partial_per_deduction': latePartialPerDeduction,
      'allowance_late_grace': allowanceLateGrace,
      'allowance_late_partial': allowanceLatePartial,
      'allowance_half_day': allowanceHalfDay,
      'allowance_short_leave': allowanceShortLeave,
      'allowance_day_leave': allowanceDayLeave,
      'advance_approval_required': advanceApprovalRequired,
      'unauthorized_absence_deduction': unauthorizedAbsenceDeduction,
    };
  }

  LeaveRulesModel copyWith({
    int? casualLeavePerYear,
    bool? sandwichBeforeAndAfter,
    bool? sandwichBeforeOnly,
    bool? sandwichAfterOnly,
    int? lateGraceMinutes,
    int? latePartialMaxMinutes,
    double? shortLeaveMaxHours,
    int? shortLeavesPerCasual,
    int? halfDayMinMinutes,
    int? halfDaysPerCasual,
    int? earlyDispersalThresholdMinutes,
    int? shortLeavesPerDeduction,
    int? halfDaysPerDeduction,
    int? lateGracePerDeduction,
    int? latePartialPerDeduction,
    int? allowanceLateGrace,
    int? allowanceLatePartial,
    int? allowanceHalfDay,
    int? allowanceShortLeave,
    int? allowanceDayLeave,
    bool? advanceApprovalRequired,
    String? unauthorizedAbsenceDeduction,
  }) {
    return LeaveRulesModel(
      casualLeavePerYear: casualLeavePerYear ?? this.casualLeavePerYear,
      sandwichBeforeAndAfter: sandwichBeforeAndAfter ?? this.sandwichBeforeAndAfter,
      sandwichBeforeOnly: sandwichBeforeOnly ?? this.sandwichBeforeOnly,
      sandwichAfterOnly: sandwichAfterOnly ?? this.sandwichAfterOnly,
      lateGraceMinutes: lateGraceMinutes ?? this.lateGraceMinutes,
      latePartialMaxMinutes: latePartialMaxMinutes ?? this.latePartialMaxMinutes,
      shortLeaveMaxHours: shortLeaveMaxHours ?? this.shortLeaveMaxHours,
      shortLeavesPerCasual: shortLeavesPerCasual ?? this.shortLeavesPerCasual,
      halfDayMinMinutes: halfDayMinMinutes ?? this.halfDayMinMinutes,
      halfDaysPerCasual: halfDaysPerCasual ?? this.halfDaysPerCasual,
      earlyDispersalThresholdMinutes: earlyDispersalThresholdMinutes ?? this.earlyDispersalThresholdMinutes,
      shortLeavesPerDeduction: shortLeavesPerDeduction ?? this.shortLeavesPerDeduction,
      halfDaysPerDeduction: halfDaysPerDeduction ?? this.halfDaysPerDeduction,
      lateGracePerDeduction: lateGracePerDeduction ?? this.lateGracePerDeduction,
      latePartialPerDeduction: latePartialPerDeduction ?? this.latePartialPerDeduction,
      allowanceLateGrace: allowanceLateGrace ?? this.allowanceLateGrace,
      allowanceLatePartial: allowanceLatePartial ?? this.allowanceLatePartial,
      allowanceHalfDay: allowanceHalfDay ?? this.allowanceHalfDay,
      allowanceShortLeave: allowanceShortLeave ?? this.allowanceShortLeave,
      allowanceDayLeave: allowanceDayLeave ?? this.allowanceDayLeave,
      advanceApprovalRequired: advanceApprovalRequired ?? this.advanceApprovalRequired,
      unauthorizedAbsenceDeduction: unauthorizedAbsenceDeduction ?? this.unauthorizedAbsenceDeduction,
    );
  }
}
