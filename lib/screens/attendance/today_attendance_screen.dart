import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/attendance/attendance_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class TodayAttendanceScreen extends StatefulWidget {
  final DateTime? initialDate;
  const TodayAttendanceScreen({super.key, this.initialDate});

  @override
  State<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends State<TodayAttendanceScreen> {
  DateTime? _selectedDate;
  String _searchQuery = '';
  DepartmentModel? _selectedDeptFilter;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchDepartments();
    provider.fetchAllEmployees();
    _fetchLogs();
  }

  void _fetchLogs() {
    if (_selectedDate == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    Provider.of<AttendanceProvider>(context, listen: false).fetchAttendance(
      dateFrom: dateStr,
      dateTo: dateStr,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007F70),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchLogs();
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

  Map<String, dynamic> _getStatusData(AttendanceModel log) {
    if (_selectedDate != null && _selectedDate!.weekday == DateTime.sunday) {
      return {'label': 'Holiday', 'color': Colors.purple, 'subtitle': 'Weekly Off'};
    }

    if (!log.isPresent) {
      return {'label': 'Absent', 'color': Colors.red, 'subtitle': null};
    }

    final lateMins = log.lateMinutes;
    if (lateMins > 0) {
      return {'label': 'Late', 'color': Colors.orange, 'subtitle': 'Late by ${lateMins}m'};
    }

    return {'label': 'Present', 'color': const Color(0xFF4CAF50), 'subtitle': null};
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    const tealColor = Color(0xFF007F70);

    final filteredLogs = provider.attendanceList.where((log) {
      final empName = log.employeeName?.toLowerCase() ?? '';
      final matchesSearch = empName.contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDeptFilter == null || log.departmentId == _selectedDeptFilter!.id;
      return matchesSearch && matchesDept;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employee name...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<DepartmentModel>(
                            isExpanded: true,
                            value: _selectedDeptFilter,
                            hint: const Text('All Departments', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem<DepartmentModel>(
                                value: null,
                                child: Text('All Departments', style: TextStyle(fontSize: 12)),
                              ),
                              ...provider.departments.map(
                                (d) => DropdownMenuItem<DepartmentModel>(
                                  value: d,
                                  child: Text(d.name, style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedDeptFilter = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tealColor,
                        side: const BorderSide(color: tealColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance Logs
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _fetchLogs(),
                    child: filteredLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'No attendance logs found for this date.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              final status = _getStatusData(log);
                              final initials = (log.employeeName ?? 'Employee').trim().split(RegExp(r'\s+'));
                              final avatarLabel = initials.length > 1
                                  ? '${initials[0][0]}${initials[1][0]}'.toUpperCase()
                                  : initials[0][0].toUpperCase();

                              final matchedEmp = provider.filterEmployees.firstWhere(
                                (e) => e.id == log.employeeId,
                                orElse: () => EmployeeModel(id: log.employeeId, name: log.employeeName ?? ''),
                              );
                              final employeeImage = matchedEmp.image;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: tealColor.withOpacity(0.08),
                                          radius: 20,
                                          backgroundImage: employeeImage != null && employeeImage.isNotEmpty
                                              ? NetworkImage(employeeImage)
                                              : null,
                                          child: employeeImage == null || employeeImage.isEmpty
                                              ? Text(
                                                  avatarLabel,
                                                  style: const TextStyle(
                                                    color: tealColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log.employeeName ?? 'Employee',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                log.departmentName ?? 'General Department',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (status['color'] as Color).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status['label'].toString().toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: status['color'],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.login_rounded, size: 14, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              'In: ${_formatTime(log.timeIn)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.logout_rounded, size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Out: ${_formatTime(log.timeOut)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        if (status['subtitle'] != null)
                                          Text(
                                            status['subtitle'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: status['color'],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
