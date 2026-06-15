import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
                  child: const Text('OK', style: TextStyle(color: const Color(0xFF007F70), fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryReportProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isEmployee = auth.user?.employeeId != null;
    const tealColor = Color(0xFF007F70);

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
                    color: Colors.black.withOpacity(0.05),
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
                  SizedBox(
                    width: double.infinity,
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
                                  child: Text(row.salary.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              Container(
                                width: totWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(row.total.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: tealColor, fontWeight: FontWeight.bold)),
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
                          'Rs. ${sheet.totals!.salarySum.toStringAsFixed(0)}',
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
                          'Rs. ${sheet.totals!.totalSum.toStringAsFixed(0)}',
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
    const tealColor = Color(0xFF007F70);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tealColor,
              borderRadius: BorderRadius.circular(16),
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
                  '${emp.designationName ?? '-'} • ${emp.departmentName ?? '-'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Divider(color: Colors.white30, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NET PAYABLE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${calc.netPayable.toStringAsFixed(0)}',
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
                          'Rs. ${str.grossSalary.toStringAsFixed(0)}',
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

          // Employee details section
          _buildSectionHeader('EMPLOYEE & BANK DETAILS'),
          const SizedBox(height: 8),
          _buildInfoGrid([
            _buildGridItem('Joining Date', emp.joiningDate != null && emp.joiningDate!.length >= 10 ? emp.joiningDate!.substring(0,10) : '-'),
            _buildGridItem('Machine Code', emp.machineCode ?? '-'),
            _buildGridItem('Bank Name', emp.bankName ?? '-'),
            _buildGridItem('Account Number', emp.accountNumber ?? '-'),
            _buildGridItem('Duty Shift', emp.dutyShiftName ?? '-'),
            _buildGridItem('Shift Timing', '${emp.shiftStart ?? '-'} - ${emp.shiftEnd ?? '-'}'),
          ]),
          const SizedBox(height: 20),

          // Attendance summary section
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
          const SizedBox(height: 20),

          // Earnings & Deductions breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('DEDUCTIONS'),
                    const SizedBox(height: 8),
                    _buildBreakdownItem('Full Day Ded.', calc.fullDayDeductionTotal, isDeduction: true),
                    _buildBreakdownItem('Half Day Ded.', calc.halfDayDeductionTotal, isDeduction: true),
                    _buildBreakdownItem('Income Tax', str.incomeTax, isDeduction: true),
                    _buildBreakdownItem('Advance Sal.', calc.advanceAmountTotal, isDeduction: true),
                    _buildBreakdownItem('Overtime (+)', calc.overtimeAmountTotal),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
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
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBreakdownItem(String name, double val, {bool isDeduction = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(
            '${isDeduction ? "-" : ""}Rs.${val.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDeduction ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
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
