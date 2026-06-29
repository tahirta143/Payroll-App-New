import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/leaves/short_leave_provider.dart';
import '../../models/leaves/short_leave_model.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';
import 'short_leaves_dialog.dart';

class ShortLeavesScreen extends StatefulWidget {
  const ShortLeavesScreen({super.key});

  @override
  State<ShortLeavesScreen> createState() => _ShortLeavesScreenState();
}

class _ShortLeavesScreenState extends State<ShortLeavesScreen> {
  String _searchQuery = '';
  EmployeeModel? _selectedEmployeeFilter;
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ShortLeaveProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;

    if (!isEmployee) {
      provider.fetchEmployees();
    }

    _fetchLeaves();
  }

  void _fetchLeaves() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ShortLeaveProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;

    final dateStr = _selectedDateFilter != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDateFilter!)
        : null;

    provider.fetchShortLeaves(
      employeeId: isEmployee ? auth.user!.employeeId : _selectedEmployeeFilter?.id,
      status: _selectedStatusFilter,
      fromDate: dateStr,
    );
  }

  void _openAddEditDialog([ShortLeaveModel? record]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShortLeavesDialog(editRecord: record),
    );
    if (result == true) {
      _fetchLeaves();
    }
  }


  void _updateStatus(int id, String status) async {
    final success = await Provider.of<ShortLeaveProvider>(context, listen: false).updateShortLeaveStatus(id, status);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Short leave status updated to $status'),
          backgroundColor: const Color(0xFF007F70),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
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

  String _fmtMinutes(int mins) {
    if (mins <= 0) return '-';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatDateString(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _selectFilterDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF007F70)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateFilter = picked;
      });
      _fetchLeaves();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedEmployeeFilter = null;
      _selectedStatusFilter = null;
      _selectedDateFilter = null;
      _searchQuery = '';
    });
    _fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ShortLeaveProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEmployee = auth.user?.employeeId != null;

    final filteredList = provider.shortLeaves.where((record) {
      final empName = record.employeeName?.toLowerCase() ?? '';
      final leaveType = record.leaveType.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return empName.contains(query) || leaveType.contains(query);
    }).toList();

    final hasActiveFilter = _selectedEmployeeFilter != null ||
        _selectedStatusFilter != null ||
        _selectedDateFilter != null ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const AppDrawer(activeRoute: '/short-leaves'),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          isEmployee ? 'My Short Leaves' : 'Short Leaves Logs',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter panels
          if (!isEmployee)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by employee or leave type...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<EmployeeModel>(
                            isExpanded: true,
                            value: _selectedEmployeeFilter,
                            hint: const Text('Filter Employee', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem<EmployeeModel>(
                                value: null,
                                child: Text('All Employees', style: TextStyle(fontSize: 12)),
                              ),
                              ...provider.employees.map((e) {
                                return DropdownMenuItem<EmployeeModel>(
                                  value: e,
                                  child: Text(e.name, style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedEmployeeFilter = val;
                              });
                              _fetchLeaves();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatusFilter,
                            hint: const Text('Filter Status', style: TextStyle(fontSize: 12)),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Statuses', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedStatusFilter = val;
                              });
                              _fetchLeaves();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[200]!),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _selectFilterDate,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[700]),
                            const SizedBox(width: 4),
                            Text(
                              _selectedDateFilter != null
                                  ? DateFormat('dd MMM').format(_selectedDateFilter!)
                                  : 'Date',
                              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                      if (hasActiveFilter) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                          onPressed: _clearFilters,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

          // Short Leaves List
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _fetchLeaves(),
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'No short leaves records found.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final record = filteredList[index];

                              Color statusBg;
                              Color statusText;
                              if (record.status == 'approved') {
                                statusBg = const Color(0xFFD1FAE5);
                                statusText = const Color(0xFF065F46);
                              } else if (record.status == 'rejected') {
                                statusBg = const Color(0xFFFEE2E2);
                                statusText = const Color(0xFF991B1B);
                              } else {
                                statusBg = const Color(0xFFFEF3C7);
                                statusText = const Color(0xFFB45309);
                              }

                              return GestureDetector(
                                onTap: () => _openAddEditDialog(record),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              record.employeeName ?? 'Employee Name',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                record.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_month, size: 13, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDateString(record.leaveDate),
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule, size: 13, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${_formatTime(record.fromTime)} - ${_formatTime(record.toTime)}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Type: ${record.leaveType}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              'Duration: ${_fmtMinutes(record.totalMinutes)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (record.reason != null && record.reason!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Reason: ${record.reason}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: record.isPaid ? const Color(0xFFEEF2FF) : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            record.isPaid ? 'PAID' : 'UNPAID',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: record.isPaid ? const Color(0xFF4F46E5) : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (!isEmployee && record.status == 'pending') ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF059669),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                  onPressed: () => _updateStatus(record.id, 'approved'),
                                                  icon: const Icon(Icons.check, size: 14),
                                                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFE15353),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                  onPressed: () => _updateStatus(record.id, 'rejected'),
                                                  icon: const Icon(Icons.close, size: 14),
                                                  label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (auth.hasPermission('can-add-short-leaves') || isEmployee)
          ? FloatingActionButton(
              backgroundColor: tealColor,
              onPressed: () => _openAddEditDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
