import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard/dashboard_provider.dart';
import '../../custom_widgets/app_drawer.dart';
import '../../custom_widgets/inkdrop_loader.dart';

import '../employees/employees_screen.dart';
import '../attendance/absents_screen.dart';
import '../attendance/today_attendance_screen.dart';
import '../leaves/dashboard_leaves_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Provider.of<DashboardProvider>(context, listen: false)
        .fetchAdminOverview(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      _loadData();
    }
  }

  Widget _buildKpiCard({
    required String label,
    required double value,
    required double change,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final positive = change >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Row(
                      children: [
                        Icon(
                          positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: positive ? const Color(0xFF10B981) : Colors.red,
                          size: 11,
                        ),
                        Text(
                          '${change.abs().toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: positive ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> trend) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No chart logs available for the selected month.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final spotsPresent = <FlSpot>[];
    final spotsAbsent = <FlSpot>[];
    final spotsLeaves = <FlSpot>[];

    for (int i = 0; i < trend.length; i++) {
      final item = trend[i];
      final day = double.tryParse(item.label) ?? (i + 1).toDouble();
      spotsPresent.add(FlSpot(day, item.present.toDouble()));
      spotsAbsent.add(FlSpot(day, item.absent.toDouble()));
      spotsLeaves.add(FlSpot(day, item.leaves.toDouble()));
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[100]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 9),
                ),
                reservedSize: 22,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Show title every 5 days for readability
                  if (value.toInt() % 5 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 9),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 20,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spotsPresent,
              isCurved: true,
              color: const Color(0xFF007F70), // present: teal
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF007F70).withOpacity(0.08),
              ),
            ),
            LineChartBarData(
              spots: spotsLeaves,
              isCurved: true,
              color: const Color(0xFFF59E0B), // leaves: orange
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsAbsent,
              isCurved: true,
              color: const Color(0xFFE15353), // absent: red
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs(List<dynamic> logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text('No clock-in logs found.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: logs.map((log) {
        final initials = log.employeeName.trim().split(RegExp(r'\s+'));
        final label = initials.length > 1
            ? '${initials[0][0]}${initials[1][0]}'.toUpperCase()
            : initials[0][0].toUpperCase();

        final isLate = log.status.toLowerCase() == 'late';
        final statusColor = isLate ? Colors.amber[700] : const Color(0xFF059669);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
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
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF007F70).withOpacity(0.08),
                radius: 18,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF007F70),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.employeeName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.departmentName ?? 'General Department',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor!.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.timeIn != null ? log.timeIn!.substring(0, 5) : '--:--',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final overview = dashboardProvider.adminOverview;
    const tealColor = Color(0xFF007F70);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: AppDrawer(activeRoute: '/dashboard'),
      body: dashboardProvider.isLoading
          ? const Center(child: InkDropLoader())
          : RefreshIndicator(
              color: tealColor,
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Date Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overview Summary',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[200]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            foregroundColor: Colors.grey[800],
                          ),
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: const Text('Filter Date', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KPIs Grid
                    if (overview != null) ...[
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 900
                            ? 4
                            : MediaQuery.of(context).size.width > 600
                                ? 3
                                : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: MediaQuery.of(context).size.width > 900
                            ? 1.8
                            : MediaQuery.of(context).size.width > 600
                                ? 1.8
                                : 1.7,
                        children: [
                          _buildKpiCard(
                            label: 'Total Employees',
                            value: overview.kpis.firstWhere((k) => k.key == 'employees').value,
                            change: overview.kpis.firstWhere((k) => k.key == 'employees').change,
                            icon: Icons.people_outline,
                            color: Colors.indigo,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EmployeesScreen()),
                              );
                            },
                          ),
                          _buildKpiCard(
                            label: 'Present Today',
                            value: overview.kpis.firstWhere((k) => k.key == 'present').value,
                            change: overview.kpis.firstWhere((k) => k.key == 'present').change,
                            icon: Icons.check_circle_outline,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TodayAttendanceScreen(initialDate: _selectedDate)),
                              );
                            },
                          ),
                          _buildKpiCard(
                            label: 'On Leave',
                            value: overview.kpis.firstWhere((k) => k.key == 'leaves').value,
                            change: overview.kpis.firstWhere((k) => k.key == 'leaves').change,
                            icon: Icons.calendar_today_outlined,
                            color: Colors.amber[800]!,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardLeavesScreen(
                                    initialDate: _selectedDate,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildKpiCard(
                            label: 'Absent',
                            value: overview.kpis.firstWhere((k) => k.key == 'absents').value,
                            change: overview.kpis.firstWhere((k) => k.key == 'absents').change,
                            icon: Icons.remove_circle_outline,
                            color: Colors.red[600]!,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AbsentsScreen(initialDate: _selectedDate)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Late card taking full width
                      Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.timer_outlined, color: Colors.orange, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Late Arrivals Today',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Requires shift checks',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                overview.lateToday.toString(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tablet/Landscape Responsive layout for Chart & Logs
                      if (MediaQuery.of(context).size.width > 900) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
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
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Monthly Trend',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _buildLegendDot(Colors.teal, 'Present'),
                                              const SizedBox(width: 8),
                                              _buildLegendDot(Colors.amber[800]!, 'Leaves'),
                                              const SizedBox(width: 8),
                                              _buildLegendDot(Colors.red[600]!, 'Absent'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      _buildTrendChart(overview.trend),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Clock-ins',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRecentLogs(overview.attendance),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile Layout - Stacking
                        Container(
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
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Monthly Trend',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildLegendDot(Colors.teal, 'Present'),
                                        const SizedBox(width: 8),
                                        _buildLegendDot(Colors.amber[800]!, 'Leaves'),
                                        const SizedBox(width: 8),
                                        _buildLegendDot(Colors.red[600]!, 'Absent'),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildTrendChart(overview.trend),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recent Attendance Card
                        const Text(
                          'Recent Clock-ins',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecentLogs(overview.attendance),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
