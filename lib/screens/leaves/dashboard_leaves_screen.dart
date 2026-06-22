import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/leaves/leave_provider.dart';
import '../../custom_widgets/inkdrop_loader.dart';

/// Shown when tapping the "On Leave" KPI card on the Admin Dashboard.
/// Displays only leaves that are active (overlapping) on [initialDate].
class DashboardLeavesScreen extends StatefulWidget {
  final DateTime initialDate;
  const DashboardLeavesScreen({super.key, required this.initialDate});

  @override
  State<DashboardLeavesScreen> createState() => _DashboardLeavesScreenState();
}

class _DashboardLeavesScreenState extends State<DashboardLeavesScreen> {
  late DateTime _selectedDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadData();
  }

  void _loadData() {
    // Fetch all leaves once — date filtering is done locally below
    Provider.of<LeaveProvider>(context, listen: false).fetchLeaves();
  }

  Future<void> _selectDate(BuildContext context) async {
    const tealColor = Color(0xFF007F70);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: tealColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      // Only update the date — data is already loaded, re-filter locally
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF007F70);
    final provider = Provider.of<LeaveProvider>(context);

    // --- Local date filter (same approach as absents_screen.dart) ---
    // Normalize to midnight: _selectedDate may carry a time component (e.g.
    // DateTime.now() = 17:21:10) which causes isAfter(to_date 00:00) to be
    // true even when to_date == today, hiding today's leaves on first open.
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final filtered = provider.leaves.where((l) {
      // Search filter
      final query = _searchQuery.toLowerCase();
      final name = l.employeeName?.toLowerCase() ?? '';
      final type = l.leaveType.toLowerCase();
      final matchesSearch = name.contains(query) || type.contains(query);

      // Date filter: check if sel falls within the leave period
      bool matchesDate = false;
      try {
        if (l.fromDate != null && l.toDate != null) {
          // Range-based leave: from_date <= sel <= to_date (all at midnight)
          final from = DateTime.parse(l.fromDate!);
          final fromDay = DateTime(from.year, from.month, from.day);
          final to = DateTime.parse(l.toDate!);
          final toDay = DateTime(to.year, to.month, to.day);
          matchesDate = !sel.isBefore(fromDay) && !sel.isAfter(toDay);
        } else if (l.date != null) {
          // Single-date leave
          final d = DateTime.parse(l.date!);
          matchesDate = d.year == sel.year &&
              d.month == sel.month &&
              d.day == sel.day;
        }
      } catch (_) {
        matchesDate = false;
      }

      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaves on Date',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by employee or leave type...',
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: const Text('Change Date',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tealColor,
                        side: const BorderSide(color: tealColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Leaves list ─────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _loadData(),
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_outlined,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No employees on leave on\n${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final record = filtered[index];

                              // Status chip colours
                              Color statusBg;
                              Color statusText;
                              String statusLabel =
                                  record.status.toUpperCase();
                              if (record.status.toLowerCase() == 'approved') {
                                statusBg = const Color(0xFFD1FAE5);
                                statusText = const Color(0xFF065F46);
                              } else if (record.status.toLowerCase() ==
                                  'rejected') {
                                statusBg = const Color(0xFFFEE2E2);
                                statusText = const Color(0xFF991B1B);
                              } else {
                                statusBg = const Color(0xFFFEF3C7);
                                statusText = const Color(0xFFB45309);
                                statusLabel = 'PENDING';
                              }

                              // Date range display
                              String dateRange = '';
                              try {
                                if (record.fromDate != null &&
                                    record.toDate != null) {
                                  final from = DateFormat('dd MMM yyyy')
                                      .format(DateTime.parse(record.fromDate!));
                                  final to = DateFormat('dd MMM yyyy')
                                      .format(DateTime.parse(record.toDate!));
                                  dateRange = '$from → $to';
                                } else if (record.date != null) {
                                  dateRange = DateFormat('dd MMM yyyy')
                                      .format(DateTime.parse(record.date!));
                                }
                              } catch (_) {
                                dateRange = record.fromDate ?? record.date ?? '';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.03),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name & status
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              record.employeeName ??
                                                  'Employee',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: statusText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Department
                                      if (record.departmentName != null &&
                                          record.departmentName!.isNotEmpty)
                                        Text(
                                          record.departmentName!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      const SizedBox(height: 8),

                                      // Leave type & days row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 12,
                                                color: Colors.amber[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                record.leaveType,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${record.days.toInt()} day(s)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Date range
                                      if (dateRange.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.date_range_outlined,
                                                size: 12,
                                                color: Colors.grey[400]),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateRange,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Reason
                                      if (record.reason != null &&
                                          record.reason!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Reason: ${record.reason}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
