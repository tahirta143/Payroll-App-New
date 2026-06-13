class AppPermissions {
  static const String all = "ALL";
  static const String canViewMainMenu = "can-view-main-menu";
  static const String canViewDashboard = "can-view-dashboard";
  static const String canViewUsers = "can-view-users";
  static const String canViewRolesAndAccess = "can-view-roles-and-access";
  static const String canViewRoles = "can-view-roles";
  static const String canViewPermissions = "can-view-permissions";

  static const String canViewHr = "can-view-hr";
  static const String canViewRequisitionForm = "can-view-requisition-form";
  static const String canViewJobPostRequest = "can-view-job-post-request";
  static const String canViewEmployeeCv = "can-view-employee-cv";
  static const String canViewInterviewLetter = "can-view-interview-letter";
  static const String canViewInterviewAssessment = "can-view-interview-assessment";
  static const String canViewInterviewPanels = "can-view-interview-panels";
  static const String canViewAssessmentReport = "can-view-assessment-report";
  static const String canViewQuizBuilder = "can-view-quiz-builder";
  static const String canViewLetterFormats = "can-view-letter-formats";

  static const String canViewPayroll = "can-view-payroll";
  static const String canViewStaffManagement = "can-view-staff-management";
  static const String canViewEmployees = "can-view-employees";
  static const String canViewSalary = "can-view-salary";
  static const String canViewShortLeaves = "can-view-short-leaves";
  static const String canViewDutyShift = "can-view-dutyshift";
  static const String canViewDepartments = "can-view-departments";
  static const String canViewDesignation = "can-view-designation";
  static const String canViewBanks = "can-view-banks";

  static const String canViewAttendanceSystem = "can-view-attandance-system";
  static const String canViewAttendance = "can-view-attendence";
  static const String canViewLeaveApplication = "can-view-leave-application";
  static const String canViewAbsent = "can-view-absent";
  static const String canViewOfficialHolidays = "can-view-official-holidays";
  static const String canViewAdvance = "can-view-advance";
  static const String canViewLeaves = "can-view-leaves";
  static const String canViewLeaveQuota = "can-view-leave-quota";
  static const String canViewFaceEnrollment = "can-view-face-enrollment";
  static const String canViewLiveFeed = "can-view-live-feed";
  static const String canViewUnknownPerson = "can-view-unknown-person";
  static const String canViewEmployeeLogs = "can-view-employee-logs";

  static const String canViewReport = "can-view-report";
  static const String canViewEmployeeListReport = "can-view-employee-list-report";
  static const String canViewHiringDurationReport = "can-view-hiring-duration-report";
  static const String canViewEmployeeInfoReport = "can-view-employee-info-report";
  static const String canViewPerformanceReviewReport = "can-view-performance-review-report";
  static const String canViewDatewiseAttendanceReport = "can-view-datewise-attendence-report";
  static const String canViewMonthlyAttendanceReport = "can-view-monthly-attendance-report";
  static const String canViewAttendanceSheetReport = "can-view-attendance-sheet-report";
  static const String canViewSalarySheetReport = "can-view-salary-sheet-report";
  static const String canViewSalarySlipReport = "can-view-salary-slip-report";
  static const String canViewBankWiseReport = "can-view-bank-wise-report";
  static const String canViewLeaveBalanceReport = "can-view-leave-balance-report";

  static const String canViewSystem = "can-view-system";
  static const String canViewDeviceControls = "can-view-device-controls";
  static const String canViewSettings = "can-view-settings";

  // Actions
  static const String canEditAttendance = "can-edit-attendence";
  static const String canDeleteAttendance = "can-delete-attendence";
  static const String canAddAttendance = "can-add-attendence";

  static const String canEditSalary = "can-edit-salary";
  static const String canDeleteSalary = "can-delete-salary";
  static const String canAddSalary = "can-add-salary";

  static const String canEditLeaves = "can-edit-leaves";
  static const String canDeleteLeaves = "can-delete-leaves";
  static const String canAddLeaves = "can-add-leaves";

  static bool hasPermission(List<dynamic>? permissions, String code) {
    if (permissions == null) return false;
    return permissions.contains(all) || permissions.contains(code);
  }

  static bool hasAnyPermission(List<dynamic>? permissions, List<String> codes) {
    if (permissions == null) return false;
    if (permissions.contains(all)) return true;
    return codes.any((code) => permissions.contains(code));
  }

  static bool hasAllPermissions(List<dynamic>? permissions, List<String> codes) {
    if (permissions == null) return false;
    if (permissions.contains(all)) return true;
    return codes.every((code) => permissions.contains(code));
  }
}
