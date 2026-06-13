class SalaryModel {
  final int id;
  final int employeeId;
  final String? employeeName;
  final double basicSalary;
  final double medicalAllowance;
  final double mobileAllowance;
  final double conveyanceAllowance;
  final double houseAllowance;
  final double utilityAllowance;
  final double miscellaneousAllowance;
  final double incomeTax;
  final bool noTax;
  final bool salaryByCash;
  final bool salaryByCheque;
  final bool salaryByTransfer;
  final String? accountNumber;
  final bool allowOvertime;
  final bool lateComingDeduction;
  final double? salaryAtAppointment;
  final String? lastIncrementDate;
  final double? incrementAmount;
  final double grossSalary;
  final double netSalary;
  final String? bankName;
  final String? createdAt;

  SalaryModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.basicSalary,
    required this.medicalAllowance,
    required this.mobileAllowance,
    required this.conveyanceAllowance,
    required this.houseAllowance,
    required this.utilityAllowance,
    required this.miscellaneousAllowance,
    required this.incomeTax,
    required this.noTax,
    required this.salaryByCash,
    required this.salaryByCheque,
    required this.salaryByTransfer,
    this.accountNumber,
    required this.allowOvertime,
    required this.lateComingDeduction,
    this.salaryAtAppointment,
    this.lastIncrementDate,
    this.incrementAmount,
    required this.grossSalary,
    required this.netSalary,
    this.bankName,
    this.createdAt,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return SalaryModel(
      id: parseInt(json['id']),
      employeeId: parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      basicSalary: parseDouble(json['basic_salary']),
      medicalAllowance: parseDouble(json['medical_allowance']),
      mobileAllowance: parseDouble(json['mobile_allowance']),
      conveyanceAllowance: parseDouble(json['conveyance_allowance']),
      houseAllowance: parseDouble(json['house_allowance']),
      utilityAllowance: parseDouble(json['utility_allowance']),
      miscellaneousAllowance: parseDouble(json['miscellaneous_allowance']),
      incomeTax: parseDouble(json['income_tax']),
      noTax: json['no_tax'] == 1 || json['no_tax'] == true,
      salaryByCash: json['salary_by_cash'] == 1 || json['salary_by_cash'] == true,
      salaryByCheque: json['salary_by_cheque'] == 1 || json['salary_by_cheque'] == true,
      salaryByTransfer: json['salary_by_transfer'] == 1 || json['salary_by_transfer'] == true,
      accountNumber: json['account_number'] as String?,
      allowOvertime: json['allow_overtime'] == 1 || json['allow_overtime'] == true,
      lateComingDeduction: json['late_coming_deduction'] == 1 || json['late_coming_deduction'] == true,
      salaryAtAppointment: json['salary_at_appointment'] != null ? parseDouble(json['salary_at_appointment']) : null,
      lastIncrementDate: json['last_increment_date'] as String?,
      incrementAmount: json['increment_amount'] != null ? parseDouble(json['increment_amount']) : null,
      grossSalary: parseDouble(json['gross_salary']),
      netSalary: parseDouble(json['net_salary']),
      bankName: json['bank_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'basic_salary': basicSalary,
      'medical_allowance': medicalAllowance,
      'mobile_allowance': mobileAllowance,
      'conveyance_allowance': conveyanceAllowance,
      'house_allowance': houseAllowance,
      'utility_allowance': utilityAllowance,
      'miscellaneous_allowance': miscellaneousAllowance,
      'income_tax': incomeTax,
      'no_tax': noTax,
      'salary_by_cash': salaryByCash,
      'salary_by_cheque': salaryByCheque,
      'salary_by_transfer': salaryByTransfer,
      'account_number': accountNumber,
      'allow_overtime': allowOvertime,
      'late_coming_deduction': lateComingDeduction,
      'salary_at_appointment': salaryAtAppointment,
      'last_increment_date': lastIncrementDate,
      'increment_amount': incrementAmount,
      'gross_salary': grossSalary,
      'net_salary': netSalary,
    };
  }
}
