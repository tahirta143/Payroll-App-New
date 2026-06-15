import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/attendance/attendance_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';
import '../../api_services/api_service.dart';
import 'attendance_dialog.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _searchController = TextEditingController();
  
  // Modes: 0 - Registry (30 days logs), 1 - Datewise Report, 2 - Monthly Report
  int _selectedMode = 0;

  // Filter values
  DepartmentModel? _selectedDeptFilter;
  EmployeeModel? _selectedEmpFilter;
  DutyShiftModel? _selectedShiftFilter;
  String _searchQuery = '';

  // Mode 1 (Datewise Report) specific state
  String _datewiseSelectedDate = '';
  List<dynamic> _datewiseRecords = [];
  bool _isDatewiseLoading = false;

  // Mode 2 (Monthly Report) specific state
  String _monthlySelectedMonth = '';
  List<dynamic> _monthlyDays = [];
  Map<String, dynamic>? _monthlySummary;
  bool _isMonthlyLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _datewiseSelectedDate = DateFormat('yyyy-MM-dd').format(now);
    _monthlySelectedMonth = DateFormat('yyyy-MM').format(now);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;
    if (!isEmployee) {
      provider.fetchDepartments();
      provider.fetchAllEmployees();
      provider.fetchDutyShifts();
    }
    _fetchAttendanceLogs();
  }

  void _fetchAttendanceLogs() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dateFrom = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    final dateTo = DateFormat('yyyy-MM-dd').format(now);

    Provider.of<AttendanceProvider>(context, listen: false).fetchAttendance(
      departmentId: isEmployee ? null : _selectedDeptFilter?.id,
      employeeId: isEmployee ? auth.user!.employeeId : _selectedEmpFilter?.id,
      dutyShiftId: _selectedShiftFilter?.id,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<void> _fetchDatewiseAttendance() async {
    setState(() {
      _isDatewiseLoading = true;
      _datewiseRecords = [];
    });
    try {
      final response = await ApiService().get('/api/datewise-attendance?date=$_datewiseSelectedDate');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _datewiseRecords = decoded['records'] as List? ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching datewise: $e');
    } finally {
      setState(() {
        _isDatewiseLoading = false;
      });
    }
  }

  Future<void> _fetchMonthlyReport() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;
    final targetEmployeeId = isEmployee ? auth.user!.employeeId : _selectedEmpFilter?.id;

    if (targetEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee first')),
      );
      return;
    }

    setState(() {
      _isMonthlyLoading = true;
      _monthlyDays = [];
      _monthlySummary = null;
    });

    try {
      final response = await ApiService().get(
        '/api/employee-monthly-report?employee_id=$targetEmployeeId&month=$_monthlySelectedMonth',
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final daysList = decoded['days'] as List? ?? [];
        
        // Calculate summary statistics
        int present = 0, leave = 0, holiday = 0, absent = 0;
        double lateMinutes = 0, overtimeMinutes = 0;

        for (var d in daysList) {
          final status = d['status']?.toString();
          if (status == 'present' || status == 'on_duty') present++;
          if (status == 'leave' || status == 'cpl') leave++;
          if (status == 'holiday') holiday++;
          if (status == 'absent') absent++;

          lateMinutes += double.tryParse(d['late_minutes']?.toString() ?? '0') ?? 0;
          overtimeMinutes += double.tryParse(d['overtime_minutes']?.toString() ?? '0') ?? 0;
        }

        setState(() {
          _monthlyDays = daysList;
          _monthlySummary = {
            'totalDays': daysList.length,
            'presentDays': present,
            'leaveDays': leave,
            'holidayDays': holiday,
            'absentDays': absent,
            'totalLate': lateMinutes,
            'totalOvertime': overtimeMinutes,
          };
        });
      }
    } catch (e) {
      debugPrint('Error fetching monthly report: $e');
    } finally {
      setState(() {
        _isMonthlyLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDeptFilter = null;
      _selectedEmpFilter = null;
      _selectedShiftFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
    if (_selectedMode == 0) {
      _fetchAttendanceLogs();
    }
  }

  void _openAddEditDialog([AttendanceModel? record]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AttendanceDialog(editRecord: record),
    );
    if (result == true) {
      _fetchAttendanceLogs();
    }
  }

  void _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this attendance record? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final success = await Provider.of<AttendanceProvider>(context, listen: false).deleteAttendance(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance record deleted successfully'),
            backgroundColor: Color(0xFF007F70),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty || time == '--:--') return '--:--';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final isPm = hour >= 12;
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMinute ${isPm ? 'PM' : 'AM'}';
    } catch (_) {
      return time;
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Map<String, dynamic> _getStatusData(dynamic log) {
    String status = log is AttendanceModel ? (log.isPresent ? 'Present' : 'Absent') : (log['status']?.toString() ?? 'Present');
    
    if (status.toLowerCase() == 'holiday') {
      return {'label': 'Holiday', 'color': Colors.purple, 'subtitle': 'Weekly Off'};
    }
    if (status.toLowerCase() == 'absent') {
      return {'label': 'Absent', 'color': Colors.red, 'subtitle': null};
    }
    if (status.toLowerCase() == 'leave') {
      return {'label': 'Leave', 'color': Colors.blue, 'subtitle': null};
    }
    if (status.toLowerCase() == 'on_duty') {
      return {'label': 'On Duty', 'color': Colors.cyan, 'subtitle': null};
    }

    int lateMins = 0;
    if (log is AttendanceModel) {
      lateMins = log.lateMinutes;
    } else {
      lateMins = double.tryParse(log['late_minutes']?.toString() ?? '0')?.toInt() ?? 0;
    }

    if (lateMins > 0) {
      return {'label': 'Late', 'color': Colors.orange, 'subtitle': 'Late by ${lateMins}m'};
    }

    return {'label': 'Present', 'color': const Color(0xFF4CAF50), 'subtitle': null};
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _datewiseSelectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _fetchDatewiseAttendance();
    }
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
                      // Year selection
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
                      // Month selection
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
        _monthlySelectedMonth = picked;
      });
      _fetchMonthlyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<AttendanceProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEmployee = auth.user?.employeeId != null;

    final filteredLogs = provider.attendanceList.where((log) {
      final empName = log.employeeName?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return empName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/attendance'),
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
          isEmployee ? 'My Attendance' : 'Attendance Dashboard',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Segmented Control (Mode Selection)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(0, 'Registry', Icons.history),
                  _buildSegmentButton(1, 'Datewise', Icons.calendar_today),
                  _buildSegmentButton(2, 'Monthly', Icons.analytics_outlined),
                ],
              ),
            ),
          ),

          // Filters Card
          if (_selectedMode == 0 && !isEmployee)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search employee name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown<DepartmentModel>(
                            value: _selectedDeptFilter,
                            hint: 'Dept',
                            items: provider.departments,
                            labelBuilder: (d) => d.name,
                            onChanged: (val) {
                              setState(() => _selectedDeptFilter = val);
                              _fetchAttendanceLogs();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown<EmployeeModel>(
                            value: _selectedEmpFilter,
                            hint: 'Employee',
                            items: provider.filterEmployees,
                            labelBuilder: (e) => e.name,
                            onChanged: (val) {
                              setState(() => _selectedEmpFilter = val);
                              _fetchAttendanceLogs();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFilterDropdown<DutyShiftModel>(
                      value: _selectedShiftFilter,
                      hint: 'Duty Shift',
                      items: provider.dutyShifts,
                      labelBuilder: (s) => s.name,
                      onChanged: (val) {
                        setState(() => _selectedShiftFilter = val);
                        _fetchAttendanceLogs();
                      },
                    ),
                  ],
                ),
              ),
            ),

          if (_selectedMode == 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today, color: tealColor),
                        label: Text('Date: $_datewiseSelectedDate', style: const TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_selectedMode == 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectMonth(context),
                            icon: const Icon(Icons.calendar_month, color: tealColor),
                            label: Text('Month: $_monthlySelectedMonth', style: const TextStyle(color: Colors.black87)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (!isEmployee) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown<EmployeeModel>(
                              value: _selectedEmpFilter,
                              hint: 'Employee',
                              items: provider.filterEmployees,
                              labelBuilder: (e) => e.name,
                              onChanged: (val) {
                                setState(() => _selectedEmpFilter = val);
                                _fetchMonthlyReport();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isEmployee) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _fetchMonthlyReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Load Monthly Report', style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),

          // Main Content
          Expanded(
            child: _buildMainContent(provider, filteredLogs),
          ),
        ],
      ),
      floatingActionButton: _selectedMode == 0 && auth.hasPermission('can-add-attendence')
          ? FloatingActionButton(
              backgroundColor: tealColor,
              onPressed: () => _openAddEditDialog(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSegmentButton(int modeIndex, String label, IconData icon) {
    final isSelected = _selectedMode == modeIndex;
    const tealColor = Color(0xFF007F70);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = modeIndex;
          });
          if (modeIndex == 1) {
            _fetchDatewiseAttendance();
          } else if (modeIndex == 2) {
            _fetchMonthlyReport();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? tealColor : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? tealColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(AttendanceProvider provider, List<AttendanceModel> filteredLogs) {
    if (_selectedMode == 0) {
      return provider.isLoading
          ? const Center(child: InkDropLoader())
          : _buildLogsTable(filteredLogs);
    } else if (_selectedMode == 1) {
      return _isDatewiseLoading
          ? const Center(child: InkDropLoader())
          : _buildDatewiseTable();
    } else {
      return _isMonthlyLoading
          ? const Center(child: InkDropLoader())
          : _buildMonthlyView();
    }
  }

  Widget _buildLogsTable(List<AttendanceModel> logs) {
    const double srWidth = 60;
    const double dateWidth = 160;
    const double timeWidth = 110;
    const double statusWidth = 130;
    const double actionWidth = 70;
    final double totalWidth = srWidth + dateWidth + (timeWidth * 2) + statusWidth + actionWidth;

    if (logs.isEmpty) {
      return const Center(child: Text('No attendance logs found.'));
    }

    return SingleChildScrollView(
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
                  _buildTableHeaderCell('Sr.No', srWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Date', dateWidth),
                  _buildTableHeaderCell('Time In', timeWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Time Out', timeWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Status', statusWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Actions', actionWidth, align: TextAlign.center),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final status = _getStatusData(log);
                  final bool isHoliday = status['label'] == 'Holiday';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: srWidth,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('${index + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          width: dateWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDisplayDate(log.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(log.employeeName ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        Container(
                          width: timeWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isHoliday && log.isPresent ? Colors.green.withAlpha(20) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                !isHoliday ? _formatTime(log.timeIn) : '--:--',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && log.isPresent ? Colors.green[700] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: timeWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isHoliday && log.timeOut != null && log.timeOut != '--:--' ? Colors.blue.withAlpha(20) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                !isHoliday ? _formatTime(log.timeOut) : '--:--',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && log.timeOut != null && log.timeOut != '--:--' ? Colors.blue[700] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: statusWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (status['color'] as Color).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    status['label'],
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status['color']),
                                  ),
                                  if (status['subtitle'] != null) ...[
                                    const SizedBox(height: 1),
                                    Text(status['subtitle'], style: TextStyle(fontSize: 8, color: (status['color'] as Color).withAlpha(180))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: actionWidth,
                          child: Center(
                            child: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') _openAddEditDialog(log);
                                if (val == 'delete') _handleDelete(log.id);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined, size: 20), title: Text('Edit', style: TextStyle(fontSize: 13)))),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, size: 20, color: Colors.red), title: Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)))),
                              ],
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              padding: EdgeInsets.zero,
                            ),
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
    );
  }

  Widget _buildDatewiseTable() {
    const double srWidth = 60;
    const double empWidth = 160;
    const double deptWidth = 120;
    const double timeWidth = 110;
    const double statusWidth = 130;
    final double totalWidth = srWidth + empWidth + deptWidth + (timeWidth * 2) + statusWidth;

    if (_datewiseRecords.isEmpty) {
      return const Center(child: Text('No datewise reports generated. Select date above.'));
    }

    return SingleChildScrollView(
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
                  _buildTableHeaderCell('Sr.No', srWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Employee', empWidth),
                  _buildTableHeaderCell('Department', deptWidth),
                  _buildTableHeaderCell('Att. In', timeWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Att. Out', timeWidth, align: TextAlign.center),
                  _buildTableHeaderCell('Status', statusWidth, align: TextAlign.center),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _datewiseRecords.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final rec = _datewiseRecords[index];
                  final emp = rec['employee'] ?? {};
                  final dept = rec['department'] ?? {};
                  final status = _getStatusData(rec);
                  final isHoliday = status['label'] == 'Holiday';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: srWidth,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('${index + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          width: empWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp['name'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('ID: ${emp['emp_id'] ?? '-'}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Container(
                          width: deptWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(dept['name'] ?? '-', style: const TextStyle(fontSize: 12)),
                        ),
                        Container(
                          width: timeWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isHoliday && rec['time_in'] != null ? Colors.green.withAlpha(20) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                !isHoliday ? _formatTime(rec['time_in']) : '--:--',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && rec['time_in'] != null ? Colors.green[700] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: timeWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isHoliday && rec['time_out'] != null ? Colors.blue.withAlpha(20) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                !isHoliday ? _formatTime(rec['time_out']) : '--:--',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && rec['time_out'] != null ? Colors.blue[700] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: statusWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (status['color'] as Color).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status['label'],
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status['color']),
                                textAlign: TextAlign.center,
                              ),
                            ),
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
    );
  }

  Widget _buildMonthlyView() {
    if (_monthlyDays.isEmpty) {
      return const Center(child: Text('No monthly attendance reports loaded. Select filters above.'));
    }

    const double dateWidth = 140;
    const double dayWidth = 100;
    const double timeWidth = 100;
    const double statusWidth = 120;
    final double totalWidth = dateWidth + dayWidth + (timeWidth * 3) + statusWidth;

    return Column(
      children: [
        // Summary KPIs
        if (_monthlySummary != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('Present', '${_monthlySummary!['presentDays']}', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('Leaves', '${_monthlySummary!['leaveDays']}', Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatCard('Holidays', '${_monthlySummary!['holidayDays']}', Colors.purple),
                  const SizedBox(width: 8),
                  _buildStatCard('Absents', '${_monthlySummary!['absentDays']}', Colors.red),
                ],
              ),
            ),
          ),

        // Table
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
                        _buildTableHeaderCell('Date', dateWidth),
                        _buildTableHeaderCell('Day', dayWidth),
                        _buildTableHeaderCell('Time In', timeWidth, align: TextAlign.center),
                        _buildTableHeaderCell('Time Out', timeWidth, align: TextAlign.center),
                        _buildTableHeaderCell('Duration', timeWidth, align: TextAlign.center),
                        _buildTableHeaderCell('Status', statusWidth, align: TextAlign.center),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _monthlyDays.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final d = _monthlyDays[index];
                        final dateStr = d['date']?.toString() ?? '';
                        final weekday = d['weekday']?.toString() ?? '';
                        final timeIn = d['time_in']?.toString();
                        final timeOut = d['time_out']?.toString();
                        final duration = d['duration_label']?.toString() ?? '-';
                        final status = _getStatusData(d);
                        final isHoliday = status['label'] == 'Holiday';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: dateWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text(_formatDisplayDate(dateStr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                              Container(
                                width: dayWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(weekday, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ),
                              Container(
                                width: timeWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !isHoliday && timeIn != null ? Colors.green.withAlpha(20) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      !isHoliday ? _formatTime(timeIn) : '--:--',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && timeIn != null ? Colors.green[700] : Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: timeWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !isHoliday && timeOut != null ? Colors.blue.withAlpha(20) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      !isHoliday ? _formatTime(timeOut) : '--:--',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isHoliday && timeOut != null ? Colors.blue[700] : Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: timeWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Text(duration, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ),
                              ),
                              Container(
                                width: statusWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: (status['color'] as Color).withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status['label'],
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status['color']),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
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
      ],
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color[700], fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color[900], fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildIconTime(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
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
}
