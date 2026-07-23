import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/salary/salary_report_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../models/salary/salary_report_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';

class SalaryReportScreen extends StatefulWidget {
  const SalaryReportScreen({super.key});

  @override
  State<SalaryReportScreen> createState() => _SalaryReportScreenState();
}

class _SalaryReportScreenState extends State<SalaryReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _selectedMonth = '';
  DepartmentModel? _selectedDeptFilter;
  EmployeeModel? _selectedEmpFilter;
  bool _hasSearched = false;

  bool _showSheet = false;
  bool _showSlip = false;
  int _tabCount = 2;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;
    _showSheet = auth.hasPermission('can-view-salary-sheet-report');
    _showSlip = auth.hasPermission('can-view-salary-slip-report') || isEmployee;

    if (_showSheet && _showSlip) {
      _tabCount = 2;
    } else {
      _tabCount = 1;
    }

    _tabController = TabController(length: _tabCount, vsync: this);
    final now = DateTime.now();
    _selectedMonth = DateFormat('yyyy-MM').format(now);

    if (isEmployee) {
      _selectedEmpFilter = EmployeeModel(
        id: auth.user!.employeeId!,
        name: auth.user!.name.isNotEmpty ? auth.user!.name : auth.user!.username,
        empId: auth.user!.username,
        designationName: auth.user!.roleLabel,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetadata();
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _hasSearched = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isCurrentlySheet() {
    if (_tabCount == 2) {
      return _tabController.index == 0;
    }
    return _showSheet;
  }

  void _loadMetadata() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.employeeId != null) return;

    final provider = Provider.of<SalaryReportProvider>(context, listen: false);
    provider.fetchDepartments();
    provider.fetchEmployees();
  }

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    final picked = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month & Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Year: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(11, (index) => now.year - 5 + index)
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedYear = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Month: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (index) => index + 1)
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(DateFormat('MMMM').format(DateTime(2026, m, 1))),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedMonth = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final monthStr = selectedMonth.toString().padLeft(2, '0');
                    Navigator.pop(context, '$selectedYear-$monthStr');
                  },
                  child: const Text('OK', style: TextStyle(color: Color(0xFF007F70), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  void _generateReport() {
    final provider = Provider.of<SalaryReportProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;

    if (_isCurrentlySheet()) {
      provider.fetchMonthlySalarySheet(
        month: _selectedMonth,
        departmentId: _selectedDeptFilter?.id,
      );
    } else {
      final empId = isEmployee ? auth.user!.employeeId! : _selectedEmpFilter?.id;
      if (empId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an employee to view salary slip'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      provider.fetchSalarySlip(
        month: _selectedMonth,
        employeeId: empId,
      );
    }
    setState(() {
      _hasSearched = true;
    });
  }

  String _formatMoney(num val) {
    return NumberFormat('#,##0.00').format(val);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMonthLabel(String ym) {
    if (ym.isEmpty) return '-';
    try {
      final parts = ym.split('-');
      if (parts.length < 2) return ym;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return ym;
    }
  }

  void _showPluginRestartDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('App Restart Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'The PDF/Printing plugin was newly added to the project.\n\n'
          'Flutter requires you to STOP the running app in your terminal or IDE, and run "flutter run" (or press Debug) to compile native plugin bindings.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF007F70), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- EXPORT PDF ---
  Future<void> _exportPdf() async {
    try {
      final provider = Provider.of<SalaryReportProvider>(context, listen: false);
      if (_isCurrentlySheet()) {
        final sheet = provider.salarySheet;
        if (sheet == null || sheet.rows.isEmpty) return;
        await _exportSalarySheetPdf(sheet);
      } else {
        final slip = provider.salarySlip;
        if (slip == null) return;
        await _exportSalarySlipPdf(slip);
      }
    } on MissingPluginException {
      _showPluginRestartDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportSalarySlipPdf(SalarySlipResponse slip) async {
    final pdf = pw.Document();
    final emp = slip.employee;
    final str = slip.salaryStructure;
    final calc = slip.payrollCalculation;
    final att = slip.attendanceSummary;

    final payModeLabel = str.salaryByTransfer
        ? "Bank Transfer"
        : str.salaryByCheque
            ? "Cheque"
            : str.salaryByCash
                ? "Cash"
                : "-";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SALARY SLIP", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text("Salary Slip - ${_formatMonthLabel(slip.month)}", style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "Dept: ${emp.departmentName ?? '-'}  |  Desig: ${emp.designationName ?? '-'}  |  Pay: $payModeLabel",
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("NET PAYABLE", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.Text("Rs. ${_formatMoney(calc.netPayable)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Employee & Bank Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("EMPLOYEE DETAILS", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text("ID: ${emp.empId ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Name: ${emp.name}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Joining: ${_formatDate(emp.joiningDate)}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Machine Code: ${emp.machineCode ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("PAYROLL & BANK", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text("Bank: ${emp.bankName ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Account: ${emp.accountNumber ?? str.accountNumber ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Shift: ${emp.dutyShiftName ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Shift Time: ${emp.shiftStart ?? '-'} - ${emp.shiftEnd ?? '-'}", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Attendance Summary
              pw.Text("ATTENDANCE SUMMARY", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ["Month Days", "Present", "Leaves", "Holidays", "Absents", "Late Days"],
                data: [
                  ["${att.monthDays}", "${att.presentDays}", "${att.leaveDays}", "${att.holidayDays}", "${att.absentDays}", "${att.lateDays}"]
                ],
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 12),

              // Earnings & Deductions
              pw.Text("EARNINGS & DEDUCTIONS", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.TableHelper.fromTextArray(
                      headers: ["Earnings", "Amount"],
                      data: [
                        ["Basic Salary", _formatMoney(str.basicSalary)],
                        ["Medical Allowance", _formatMoney(str.medicalAllowance)],
                        ["Mobile Allowance", _formatMoney(str.mobileAllowance)],
                        ["Conveyance Allowance", _formatMoney(str.conveyanceAllowance)],
                        ["House Allowance", _formatMoney(str.houseAllowance)],
                        ["Utility Allowance", _formatMoney(str.utilityAllowance)],
                        ["Misc Allowance", _formatMoney(str.miscellaneousAllowance)],
                        ["Gross Salary", _formatMoney(str.grossSalary)],
                      ],
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.TableHelper.fromTextArray(
                      headers: ["Deductions / Additions", "Amount"],
                      data: [
                        if (emp.allowLateComing && emp.allowDeductions) ["Attendance Deduction", _formatMoney(calc.attendanceDeductionTotal)],
                        ["Income Tax", str.noTax ? "0 (No Tax)" : _formatMoney(str.incomeTax)],
                        ["Advance Salary", _formatMoney(calc.advanceAmountTotal)],
                        if (emp.allowOvertime) ["Overtime", _formatMoney(calc.overtimeAmountTotal)],
                        ["Net Payable", _formatMoney(calc.netPayable)],
                      ],
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Signatures
              pw.Text("SIGNATURES", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 160,
                    height: 40,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    alignment: pw.Alignment.bottomCenter,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("PREPARED BY", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    width: 160,
                    height: 40,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    alignment: pw.Alignment.bottomCenter,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("APPROVED BY", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    width: 160,
                    height: 40,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    alignment: pw.Alignment.bottomCenter,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("EMPLOYEE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text("This is a computer generated salary slip and does not require a stamp.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportSalarySheetPdf(MonthlySalarySheetResponse sheet) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Text("MONTHLY SALARY SHEET - ${_formatMonthLabel(sheet.month)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ["Employee", "Designation", "Unit/Dept", "Bank Account", "Days", "Base Salary", "Total Pay"],
              data: sheet.rows.map((r) => [
                r.employee ?? '-',
                r.designation ?? '-',
                r.unit ?? '-',
                r.accountNumber ?? '-',
                r.daysCount.toStringAsFixed(0),
                _formatMoney(r.salary),
                _formatMoney(r.total),
              ]).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            if (sheet.totals != null) ...[
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Total Salary: Rs. ${_formatMoney(sheet.totals!.salarySum)}   |   Total Payable: Rs. ${_formatMoney(sheet.totals!.totalSum)}",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                ],
              ),
            ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- EXPORT CSV ---
  Future<void> _exportCsv() async {
    final provider = Provider.of<SalaryReportProvider>(context, listen: false);
    List<List<dynamic>> rows = [];
    String fileName = "salary_report.csv";

    if (_isCurrentlySheet()) {
      final sheet = provider.salarySheet;
      if (sheet == null || sheet.rows.isEmpty) return;
      fileName = "salary_sheet_${sheet.month}.csv";

      rows.add(["MONTHLY SALARY SHEET"]);
      rows.add(["Month", _formatMonthLabel(sheet.month)]);
      rows.add([]);
      rows.add(["Employee", "Designation", "Unit/Dept", "Bank Account", "Days", "Base Salary", "Total Pay"]);

      for (var r in sheet.rows) {
        rows.add([
          r.employee ?? '-',
          r.designation ?? '-',
          r.unit ?? '-',
          r.accountNumber ?? '-',
          r.daysCount,
          r.salary,
          r.total,
        ]);
      }

      if (sheet.totals != null) {
        rows.add([]);
        rows.add(["TOTAL SALARY", sheet.totals!.salarySum]);
        rows.add(["TOTAL PAYABLE", sheet.totals!.totalSum]);
      }
    } else {
      final slip = provider.salarySlip;
      if (slip == null) return;
      final emp = slip.employee;
      final str = slip.salaryStructure;
      final calc = slip.payrollCalculation;
      final att = slip.attendanceSummary;
      fileName = "salary_slip_${emp.empId ?? 'employee'}_${slip.month}.csv";

      rows = [
        ["SALARY SLIP"],
        ["Month", _formatMonthLabel(slip.month)],
        [],
        ["Employee Information"],
        ["Employee ID", emp.empId ?? '-'],
        ["Employee Name", emp.name],
        ["Department", emp.departmentName ?? '-'],
        ["Designation", emp.designationName ?? '-'],
        ["Joining Date", _formatDate(emp.joiningDate)],
        [],
        ["Payroll & Bank"],
        ["Bank", emp.bankName ?? '-'],
        ["Account Number", emp.accountNumber ?? str.accountNumber ?? '-'],
        ["Shift", emp.dutyShiftName ?? '-'],
        ["Shift Time", "${emp.shiftStart ?? '-'} - ${emp.shiftEnd ?? '-'}"],
        [],
        ["Attendance Summary"],
        ["Month Days", att.monthDays],
        ["Present Days", att.presentDays],
        ["Leave Days", att.leaveDays],
        ["Holiday Days", att.holidayDays],
        ["Absent Days", att.absentDays],
        ["Late Days", att.lateDays],
        [],
        ["Earnings"],
        ["Basic Salary", str.basicSalary],
        ["Medical Allowance", str.medicalAllowance],
        ["Mobile Allowance", str.mobileAllowance],
        ["Conveyance Allowance", str.conveyanceAllowance],
        ["House Allowance", str.houseAllowance],
        ["Utility Allowance", str.utilityAllowance],
        ["Misc Allowance", str.miscellaneousAllowance],
        ["Gross Salary", str.grossSalary],
        [],
        ["Deductions & Additions"],
        ["Attendance Deduction", calc.attendanceDeductionTotal],
        ["Income Tax", str.noTax ? 0 : str.incomeTax],
        ["Advance Salary", calc.advanceAmountTotal],
        ["Overtime Amount", calc.overtimeAmountTotal],
        ["Net Payable", calc.netPayable],
      ];
    }

    try {
      final csvString = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvString);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } on MissingPluginException {
      _showPluginRestartDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV Export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- PRINT ---
  Future<void> _printReport() async {
    await _exportPdf();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryReportProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isEmployee = auth.user?.employeeId != null;
    const tealColor = Color(0xFF007F70);

    final hasData = _isCurrentlySheet()
        ? (provider.salarySheet != null && provider.salarySheet!.rows.isNotEmpty)
        : (provider.salarySlip != null);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/salary-reports'),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _tabCount == 2
              ? 'Salary Reports'
              : (_showSheet ? 'Salary Sheet Report' : 'Salary Slip'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: _tabCount == 2
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.table_chart_outlined), text: 'Salary Sheet'),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Salary Slip'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Filter Panel Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Month Selection Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectMonth(context),
                          icon: const Icon(Icons.calendar_month, color: tealColor, size: 18),
                          label: Text(
                            'Month: $_selectedMonth',
                            style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_isCurrentlySheet() || !isEmployee) ...[
                        const SizedBox(width: 12),
                        // Conditional filter (Dept or Employee)
                        Expanded(
                          child: _isCurrentlySheet()
                              ? _buildFilterDropdown<DepartmentModel>(
                                  value: _selectedDeptFilter,
                                  hint: 'Department',
                                  items: provider.departments,
                                  labelBuilder: (d) => d.name,
                                  onChanged: (val) {
                                    setState(() => _selectedDeptFilter = val);
                                  },
                                )
                              : _buildFilterDropdown<EmployeeModel>(
                                  value: _selectedEmpFilter,
                                  hint: 'Employee',
                                  items: provider.employees,
                                  labelBuilder: (e) => e.name,
                                  onChanged: (val) {
                                    setState(() => _selectedEmpFilter = val);
                                  },
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                          label: const Text(
                            'Generate Report',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      if (hasData) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF0F172A), size: 20),
                          tooltip: 'Export PDF',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download, color: Color(0xFF0F172A), size: 20),
                          tooltip: 'Export CSV',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _printReport,
                          icon: const Icon(Icons.print, color: Color(0xFF334155), size: 20),
                          tooltip: 'Print',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content Pane
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.query_stats_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Select filters and click Generate',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : provider.error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                provider.error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _isCurrentlySheet()
                            ? _buildSalarySheetView(provider.salarySheet)
                            : _buildSalarySlipView(provider.salarySlip),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySheetView(MonthlySalarySheetResponse? sheet) {
    if (sheet == null || sheet.rows.isEmpty) {
      return const Center(child: Text('No salary records found for this period.'));
    }

    const tealColor = Color(0xFF007F70);

    const double empWidth = 140;
    const double desigWidth = 110;
    const double unitWidth = 100;
    const double bankWidth = 120;
    const double daysWidth = 70;
    const double salWidth = 90;
    const double totWidth = 90;
    final double totalWidth = empWidth + desigWidth + unitWidth + bankWidth + daysWidth + salWidth + totWidth;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeaderCell('Employee', empWidth),
                        _buildTableHeaderCell('Designation', desigWidth),
                        _buildTableHeaderCell('Unit/Dept', unitWidth),
                        _buildTableHeaderCell('Bank Account', bankWidth),
                        _buildTableHeaderCell('Days', daysWidth, align: TextAlign.center),
                        _buildTableHeaderCell('Base Sal', salWidth, align: TextAlign.right),
                        _buildTableHeaderCell('Total Pay', totWidth, align: TextAlign.right),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sheet.rows.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final row = sheet.rows[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: empWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text(row.employee ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                width: desigWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(row.designation ?? '-', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ),
                              Container(
                                width: unitWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(row.unit ?? '-', style: const TextStyle(fontSize: 11)),
                              ),
                              Container(
                                width: bankWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(row.accountNumber ?? '-', style: const TextStyle(fontSize: 11)),
                              ),
                              Container(
                                width: daysWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Text(row.daysCount.toStringAsFixed(0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Container(
                                width: salWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_formatMoney(row.salary), style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              Container(
                                width: totWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_formatMoney(row.total), style: const TextStyle(fontSize: 12, color: tealColor, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Totals sticky footer
        if (sheet.totals != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL SALARY', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${_formatMoney(sheet.totals!.salarySum)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL PAYABLE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${_formatMoney(sheet.totals!.totalSum)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSalarySlipView(SalarySlipResponse? slip) {
    if (slip == null) {
      return const Center(child: Text('No salary slip loaded.'));
    }

    final emp = slip.employee;
    final str = slip.salaryStructure;
    final calc = slip.payrollCalculation;
    final att = slip.attendanceSummary;
    final set = slip.settingsUsed;
    const tealColor = Color(0xFF007F70);

    final payModeLabel = str.salaryByTransfer
        ? "Bank Transfer"
        : str.salaryByCheque
            ? "Cheque"
            : str.salaryByCash
                ? "Cash"
                : "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tealColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: tealColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      emp.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${emp.empId ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp.designationName ?? '-'} • ${emp.departmentName ?? '-'} • Pay Mode: $payModeLabel',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),

                // Employee Flag Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildFlagChip("OT ${emp.allowOvertime ? 'On' : 'Off'}", emp.allowOvertime ? const Color(0xFF10B981) : Colors.white54),
                    _buildFlagChip("Late ${emp.allowLateComing ? 'Tracked' : 'Ignored'}", emp.allowLateComing ? Colors.amber : Colors.white54),
                    _buildFlagChip("Deductions ${emp.allowLateComing && emp.allowDeductions ? 'Applied' : 'Off'}", emp.allowLateComing && emp.allowDeductions ? const Color(0xFFF43F5E) : Colors.white54),
                  ],
                ),

                const Divider(color: Colors.white30, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NET PAYABLE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${_formatMoney(calc.netPayable)}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('GROSS SALARY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${_formatMoney(str.grossSalary)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Employee & Bank details section
          _buildSectionHeader('EMPLOYEE & BANK DETAILS'),
          const SizedBox(height: 8),
          _buildInfoGrid([
            _buildGridItem('Joining Date', _formatDate(emp.joiningDate)),
            _buildGridItem('Machine Code', emp.machineCode ?? '-'),
            _buildGridItem('Bank Name', emp.bankName ?? '-'),
            _buildGridItem('Account Number', emp.accountNumber ?? str.accountNumber ?? '-'),
            _buildGridItem('Duty Shift', emp.dutyShiftName ?? '-'),
            _buildGridItem('Shift Timing', '${emp.shiftStart ?? '-'} - ${emp.shiftEnd ?? '-'}'),
          ]),
          const SizedBox(height: 16),

          // 3. Attendance summary section
          _buildSectionHeader('ATTENDANCE SUMMARY'),
          const SizedBox(height: 8),
          _buildInfoGrid([
            _buildGridItem('Month Days', '${att.monthDays}'),
            _buildGridItem('Present Days', '${att.presentDays}'),
            _buildGridItem('Absent Days', '${att.absentDays}'),
            _buildGridItem('Leave Days', '${att.leaveDays}'),
            _buildGridItem('Holiday Days', '${att.holidayDays}'),
            _buildGridItem('Late Days', '${att.lateDays}'),
          ]),
          const SizedBox(height: 16),

          // 4. Earnings & Deductions breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('EARNINGS'),
                    const SizedBox(height: 8),
                    _buildBreakdownItem('Basic Salary', str.basicSalary),
                    _buildBreakdownItem('Medical', str.medicalAllowance),
                    _buildBreakdownItem('Mobile', str.mobileAllowance),
                    _buildBreakdownItem('Conveyance', str.conveyanceAllowance),
                    _buildBreakdownItem('House', str.houseAllowance),
                    _buildBreakdownItem('Utility', str.utilityAllowance),
                    _buildBreakdownItem('Miscellaneous', str.miscellaneousAllowance),
                    _buildBreakdownItem('Gross Salary', str.grossSalary, isTotal: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Deductions & Additions Side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('DEDUCTIONS & ADDITIONS'),
                    const SizedBox(height: 8),
                    if (emp.allowLateComing && emp.allowDeductions)
                      _buildBreakdownItem('Attendance Ded.', calc.attendanceDeductionTotal, isDeduction: true),
                    _buildBreakdownItem('Income Tax', str.incomeTax, isDeduction: true, overrideText: str.noTax ? "0 (No Tax)" : null),
                    _buildBreakdownItem('Advance Sal.', calc.advanceAmountTotal, isDeduction: true),
                    if (emp.allowOvertime) ...[
                      _buildBreakdownItem('Overtime (+)', calc.overtimeAmountTotal, isCredit: true),
                      // Overtime Rate Info Box
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OVERTIME RATE INFO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                            const SizedBox(height: 4),
                            Text('Per Hr: Rs. ${_formatMoney(calc.overtimePerHourSalary)}', style: const TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                            Text('Multiplier: ×${calc.overtimeMultiplier}', style: const TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                            Text('Effective/hr: Rs. ${_formatMoney(calc.overtimeEffectiveRate)}', style: const TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                            Text('Total Mins: ${calc.overtimeMinutesTotal} mins', style: const TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                          ],
                        ),
                      ),
                    ],
                    _buildBreakdownItem('Net Payable', calc.netPayable, isTotal: true, isCredit: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Settings Used Summary Card
          if (set != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SETTINGS USED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text('Max Late: ${set.maxLateTime ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      Text('Half Day %: ${set.halfDayDeductionPercent ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      Text('Full Day %: ${set.fullDayDeductionPercent ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 6. Deduction Breakdown Table Section
          if (calc.deductionBreakdown != null) ...[
            _buildSectionHeader('DEDUCTION BREAKDOWN'),
            const SizedBox(height: 6),

            // Per Day Rates Header Chips
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('Per Day: Rs. ${_formatMoney(calc.perDaySalary)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('Full Day: Rs. ${_formatMoney(calc.fullDayRate)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('Half Day: Rs. ${_formatMoney(calc.halfDayRate)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('1/3 Day: Rs. ${_formatMoney(calc.thirdDayRate)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Rule Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: Colors.grey[50],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('RULE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('CHG', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('UNITS', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 3, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Rows
                  _buildBreakdownRow('Late (Grace)', calc.deductionBreakdown?.lateGrace, Colors.amber[800]!),
                  _buildBreakdownRow('Late (1/3 Day)', calc.deductionBreakdown?.latePartial, Colors.amber[800]!),
                  _buildBreakdownRow('Half Day', calc.deductionBreakdown?.halfDay, Colors.red[700]!),
                  _buildBreakdownRow('Short Leave', calc.deductionBreakdown?.shortLeave, Colors.indigo[700]!),
                  _buildBreakdownRow('Absent / Sandwich', calc.deductionBreakdown?.absent, Colors.red[700]!),

                  // Total Deduction Footer
                  Container(
                    color: Colors.grey[50],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Attendance Deduction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Rs. ${_formatMoney(calc.attendanceDeductionTotal)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 7. Signatures Section
          _buildSectionHeader('SIGNATURES'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignatureBox('Prepared By'),
                    _buildSignatureBox('Approved By'),
                    _buildSignatureBox('Employee'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is a computer generated salary slip and does not require a stamp.',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFlagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: children,
      ),
    );
  }

  Widget _buildGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String name,
    double val, {
    bool isDeduction = false,
    bool isCredit = false,
    bool isTotal = false,
    String? overrideText,
  }) {
    final valText = overrideText ?? 'Rs. ${_formatMoney(val)}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isTotal ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isTotal ? Colors.grey[300]! : Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black87 : Colors.black54,
            ),
          ),
          Text(
            valText,
            style: TextStyle(
              fontSize: isTotal ? 12 : 11,
              fontWeight: FontWeight.bold,
              color: isDeduction
                  ? Colors.red[700]
                  : isCredit
                      ? const Color(0xFF059669)
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, DeductionBreakdownRow? row, Color labelColor) {
    if (row == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.chargeable}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.deductionUnits.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.rate > 0 ? 'Rs. ${_formatMoney(row.rate)}' : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.amount > 0 ? 'Rs. ${_formatMoney(row.amount)}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: row.amount > 0 ? Colors.red[700] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBox(String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: 1, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          items: [
            DropdownMenuItem<T>(value: null, child: Text('All $hint', style: const TextStyle(fontSize: 12))),
            ...items.map((item) => DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item), style: const TextStyle(fontSize: 12)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, double width, {TextAlign align = TextAlign.start}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}
