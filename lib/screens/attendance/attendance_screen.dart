import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/attendance/attendance_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';
import 'attendance_dialog.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _searchController = TextEditingController();
  
  DepartmentModel? _selectedDeptFilter;
  EmployeeModel? _selectedEmpFilter;
  DutyShiftModel? _selectedShiftFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    
    // Default range: last 30 days
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

  void _clearFilters() {
    setState(() {
      _selectedDeptFilter = null;
      _selectedEmpFilter = null;
      _selectedShiftFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchAttendanceLogs();
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

  Widget _buildTableHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
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

    final hasActiveFilters = _selectedDeptFilter != null || _selectedEmpFilter != null || _selectedShiftFilter != null || _searchQuery.isNotEmpty;

    // Define column widths for the custom table
    const double dateWidth = 110;
    const double empWidth = 160;
    const double timeWidth = 100;
    const double shiftWidth = 140;
    const double actionWidth = 70;

    final double totalTableWidth = dateWidth + (isEmployee ? 0 : empWidth) + (timeWidth * 2) + shiftWidth + actionWidth;

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
          isEmployee ? 'My Attendance' : 'Attendance Registry',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          if (!isEmployee)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                ],
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
                    style: const TextStyle(fontSize: 13),
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

          // Custom Table with Sticky Header
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _fetchAttendanceLogs(),
                    child: filteredLogs.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No attendance logs found.', style: TextStyle(color: Colors.grey))),
                            ],
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalTableWidth,
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    color: Colors.grey[100],
                                    child: Row(
                                      children: [
                                        _buildTableHeaderCell('Date', dateWidth),
                                        if (!isEmployee) _buildTableHeaderCell('Employee', empWidth),
                                        _buildTableHeaderCell('Time In', timeWidth),
                                        _buildTableHeaderCell('Time Out', timeWidth),
                                        _buildTableHeaderCell('Shift', shiftWidth),
                                        _buildTableHeaderCell('Actions', actionWidth),
                                      ],
                                    ),
                                  ),
                                  // Table Body
                                  Expanded(
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: filteredLogs.length,
                                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                                      itemBuilder: (context, index) {
                                        final log = filteredLogs[index];
                                        return InkWell(
                                          onTap: () {}, // Optional row tap
                                          child: Row(
                                            children: [
                                              _buildTableCell(Text(log.date.length >= 10 ? log.date.substring(0, 10) : log.date, style: const TextStyle(fontSize: 12)), dateWidth),
                                              if (!isEmployee) _buildTableCell(Text(log.employeeName ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tealColor)), empWidth),
                                              _buildTableCell(Text(_formatTime(log.timeIn), style: const TextStyle(fontSize: 12)), timeWidth),
                                              _buildTableCell(Text(_formatTime(log.timeOut), style: const TextStyle(fontSize: 12)), timeWidth),
                                              _buildTableCell(Text(log.dutyShiftName ?? '--', style: const TextStyle(fontSize: 11, color: Colors.grey)), shiftWidth),
                                              _buildTableCell(
                                                PopupMenuButton<String>(
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
                                                actionWidth,
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
          ),
        ],
      ),
      floatingActionButton: auth.hasPermission('can-add-attendence')
          ? FloatingActionButton(
              backgroundColor: tealColor,
              onPressed: () => _openAddEditDialog(),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
