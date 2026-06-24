import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/attendance/attendance_sheet_provider.dart';
import '../../models/attendance/attendance_sheet_model.dart';
import '../../models/attendance/attendance_model.dart'; // DepartmentModel, EmployeeModel
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';

class AttendanceSheetScreen extends StatefulWidget {
  const AttendanceSheetScreen({super.key});

  @override
  State<AttendanceSheetScreen> createState() => _AttendanceSheetScreenState();
}

class _AttendanceSheetScreenState extends State<AttendanceSheetScreen> {
  final _searchController = TextEditingController();
  String _selectedMonth = '';
  String _filterType = 'all';
  DepartmentModel? _selectedDept;
  EmployeeModel? _selectedEmp;
  String _searchQuery = '';
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('yyyy-MM').format(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceSheetProvider>(context, listen: false).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onDeptChanged(DepartmentModel? dept) {
    setState(() {
      _selectedDept = dept;
      _selectedEmp = null;
    });
    if (_filterType == 'employee' && dept != null) {
      Provider.of<AttendanceSheetProvider>(context, listen: false).fetchEmployeesForDepartment(dept.id);
    }
  }

  void _generateSheet() {
    if (_filterType == 'department' && _selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_filterType == 'employee' && _selectedEmp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee'), backgroundColor: Colors.orange),
      );
      return;
    }

    final provider = Provider.of<AttendanceSheetProvider>(context, listen: false);
    provider.fetchAttendanceSheet(
      month: _selectedMonth,
      filterType: _filterType,
      departmentId: _selectedDept?.id,
      employeeId: _selectedEmp?.id,
    );
    setState(() {
      _hasGenerated = true;
    });
  }

  // Visual status styler mapping
  final Map<String, _StatusStyle> _statusStyles = {
    'P': _StatusStyle(bg: const Color(0xFFF0FDF4), text: const Color(0xFF166534), border: const Color(0xFFBBF7D0), label: 'Present'),
    'A': _StatusStyle(bg: const Color(0xFFFFF1F2), text: const Color(0xFF9F1239), border: const Color(0xFFFECDD3), label: 'Absent'),
    'L': _StatusStyle(bg: const Color(0xFFEFF6FF), text: const Color(0xFF1E40AF), border: const Color(0xFFBFDBFE), label: 'Leave'),
    'CPL': _StatusStyle(bg: const Color(0xFFECFEFF), text: const Color(0xFF0E7490), border: const Color(0xFFA5F3FC), label: 'CPL'),
    'OD': _StatusStyle(bg: const Color(0xFFF0F9FF), text: const Color(0xFF075985), border: const Color(0xFFBAE6FD), label: 'On Duty'),
    'HD': _StatusStyle(bg: const Color(0xFFFFFBEB), text: const Color(0xFF92400E), border: const Color(0xFFFDE68A), label: 'Half Day'),
    'OL': _StatusStyle(bg: const Color(0xFFF5F3FF), text: const Color(0xFF5B21B6), border: const Color(0xFFDDD6FE), label: 'On Leave'),
  };

  _StatusStyle _getStatusStyle(String code) {
    return _statusStyles[code] ?? _StatusStyle(
      bg: const Color(0xFFF8FAFC),
      text: const Color(0xFF475569),
      border: const Color(0xFFE2E8F0),
      label: code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceSheetProvider>(context);
    const tealColor = Color(0xFF007F70);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/attendance-sheet'),
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
        title: const Text(
          'Attendance Sheet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter card panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterPanel(provider),
          ),

          // Main data viewport
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : !_hasGenerated
                    ? _buildPlaceholderState(
                        icon: Icons.calendar_month_outlined,
                        title: 'Ready to generate report',
                        subtitle: 'Select a month and filters above, then click Generate Sheet',
                      )
                    : provider.error != null
                        ? _buildPlaceholderState(
                            icon: Icons.error_outline,
                            title: 'Error loading attendance',
                            subtitle: provider.error!,
                            isError: true,
                          )
                        : (provider.attendanceSheet == null || provider.attendanceSheet!.employees.isEmpty)
                            ? _buildPlaceholderState(
                                icon: Icons.info_outline,
                                title: 'No attendance data found',
                                subtitle: 'Try adjusting your filters or selecting a different month',
                              )
                            : _buildSheetTable(provider.attendanceSheet!),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: isError ? Colors.red[300] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(AttendanceSheetProvider provider) {
    const tealColor = Color(0xFF007F70);
    final isWide = MediaQuery.of(context).size.width > 800;

    final filterWidgets = [
      // 1. Search Box
      SizedBox(
        width: isWide ? 190 : double.infinity,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search employee...',
            prefixIcon: const Icon(Icons.search, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ),
      const SizedBox(width: 8, height: 8),

      // 2. Month Selector
      SizedBox(
        width: isWide ? 140 : double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _selectMonth(context),
          icon: const Icon(Icons.calendar_month, color: tealColor, size: 16),
          label: Text(
            'Month: $_selectedMonth',
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      const SizedBox(width: 8, height: 8),

      // 3. Filter pills
      _buildFilterPills(),
      const SizedBox(width: 8, height: 8),

      // 4. Department Dropdown
      if (_filterType == 'department' || _filterType == 'employee') ...[
        SizedBox(
          width: isWide ? 150 : double.infinity,
          child: _buildFilterDropdown<DepartmentModel>(
            value: _selectedDept,
            hint: 'Department',
            items: provider.departments,
            labelBuilder: (d) => d.name,
            onChanged: _onDeptChanged,
          ),
        ),
        const SizedBox(width: 8, height: 8),
      ],

      // 5. Employee Dropdown
      if (_filterType == 'employee') ...[
        SizedBox(
          width: isWide ? 160 : double.infinity,
          child: _buildFilterDropdown<EmployeeModel>(
            value: _selectedEmp,
            hint: 'Employee',
            items: provider.employees,
            labelBuilder: (e) => e.name,
            onChanged: (val) => setState(() => _selectedEmp = val),
          ),
        ),
        const SizedBox(width: 8, height: 8),
      ],

      // 6. Action button
      SizedBox(
        width: isWide ? null : double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: tealColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
          ),
          icon: const Icon(Icons.flash_on, color: Colors.white, size: 16),
          label: const Text(
            'Generate Sheet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isWide
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterWidgets,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: filterWidgets,
            ),
    );
  }

  Widget _buildFilterPills() {
    final pillOptions = [
      {'value': 'all', 'label': 'All', 'icon': Icons.group_outlined},
      {'value': 'department', 'label': 'Department', 'icon': Icons.business_outlined},
      {'value': 'employee', 'label': 'Employee', 'icon': Icons.person_outline},
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: pillOptions.map((opt) {
          final isSelected = _filterType == opt['value'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _filterType = opt['value'] as String;
                _selectedDept = null;
                _selectedEmp = null;
              });
              final provider = Provider.of<AttendanceSheetProvider>(context, listen: false);
              if (_filterType == 'department' || _filterType == 'employee') {
                provider.fetchDepartments();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    size: 14,
                    color: isSelected ? const Color(0xFF007F70) : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF007F70) : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
          hint: Text(hint, style: const TextStyle(fontSize: 11)),
          items: [
            DropdownMenuItem<T>(value: null, child: Text('All $hint', style: const TextStyle(fontSize: 11))),
            ...items.map((item) => DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item), style: const TextStyle(fontSize: 11)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSheetTable(MonthlyAttendanceSheetResponse sheet) {
    // 1. Group & filter employees
    final filteredEmployees = sheet.employees.where((emp) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return emp.name.toLowerCase().contains(q) ||
          emp.empId.toLowerCase().contains(q) ||
          emp.departmentName.toLowerCase().contains(q);
    }).toList();

    final Map<String, List<MonthlyAttendanceEmployee>> grouped = {};
    for (var emp in filteredEmployees) {
      final d = emp.departmentName.isNotEmpty ? emp.departmentName : 'Others';
      if (!grouped.containsKey(d)) {
        grouped[d] = [];
      }
      grouped[d]!.add(emp);
    }
    final groupedKeys = grouped.keys.toList();

    // 2. Compute widths
    const double srWidth = 45.0;
    const double empWidth = 160.0;
    const double dayWidth = 36.0;
    final double totalTableWidth = srWidth + empWidth + (sheet.days.length * dayWidth);

    int sequentialSr = 0;

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalTableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      _buildHeaderRow(sheet.days, srWidth, empWidth, dayWidth),

                      if (filteredEmployees.isEmpty)
                        Container(
                          width: totalTableWidth,
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'No employees match your search query',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ),

                      // Department Groupings
                      ...groupedKeys.map((deptName) {
                        final empList = grouped[deptName] ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDepartmentRow(deptName, empList.length, totalTableWidth),
                            ...empList.map((emp) {
                              sequentialSr++;
                              return _buildEmployeeRow(
                                emp: emp,
                                days: sheet.days,
                                srWidth: srWidth,
                                empWidth: empWidth,
                                dayWidth: dayWidth,
                                index: sequentialSr,
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Legend indicator
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeaderRow(List<MonthlyAttendanceDay> days, double srWidth, double empWidth, double dayWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            width: srWidth,
            height: 40,
            alignment: Alignment.center,
            child: const Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
          ),
          Container(
            width: empWidth,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: const Text('Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          ),
          ...days.map((d) {
            return Container(
              width: dayWidth,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: d.isWeekend ? Colors.grey[100] : Colors.transparent,
              ),
              child: Text(
                '${d.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: d.isWeekend ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(String departmentName, int employeeCount, double totalWidth) {
    const tealColor = Color(0xFF007F70);

    return Container(
      width: totalWidth,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE6F4F2), // React `#e6f4f2`
        border: Border(
          bottom: BorderSide(color: Color(0xFFCCFBF1)), // React `#ccfbf1`
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_outlined, size: 13, color: tealColor),
          const SizedBox(width: 6),
          Text(
            departmentName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: tealColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$employeeCount employee${employeeCount != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: tealColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow({
    required MonthlyAttendanceEmployee emp,
    required List<MonthlyAttendanceDay> days,
    required double srWidth,
    required double empWidth,
    required double dayWidth,
    required int index,
  }) {
    final bool isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          // Serial Number
          Container(
            width: srWidth,
            height: 46,
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),

          // Employee Profile Name & ID
          Container(
            width: empWidth,
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emp.name.isNotEmpty ? emp.name : 'Unknown',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (emp.empId.isNotEmpty)
                  Text(
                    emp.empId,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Day Badges
          ...List.generate(days.length, (idx) {
            final day = days[idx];
            final statusObj = idx < emp.statuses.length ? emp.statuses[idx] : null;
            final code = statusObj?.code ?? '';
            final reason = statusObj?.reason ?? '';
            final styleObj = _getStatusStyle(code);

            final String tooltipText = reason.isNotEmpty
                ? '${emp.name} · Day ${day.day}\nReason: $reason'
                : '${emp.name} · Day ${day.day}';

            return Container(
              width: dayWidth,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: day.isWeekend ? const Color(0xFFF9FAFB) : Colors.transparent,
              ),
              child: Tooltip(
                message: tooltipText,
                preferBelow: false,
                triggerMode: TooltipTriggerMode.tap, // Handles tap-to-tooltip seamlessly on mobile
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 25,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: styleObj.bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: styleObj.border, width: 1),
                        ),
                        child: Text(
                          code.isNotEmpty ? code : '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: styleObj.text,
                          ),
                        ),
                      ),
                      if (reason.isNotEmpty)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _statusStyles.entries.map((entry) {
            final code = entry.key;
            final s = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: s.border),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: s.text),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  s.label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color bg;
  final Color text;
  final Color border;
  final String label;

  _StatusStyle({
    required this.bg,
    required this.text,
    required this.border,
    required this.label,
  });
}
