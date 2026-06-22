import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/dashboard/dashboard_provider.dart';
import '../../custom_widgets/app_drawer.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadData();
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = auth.user?.employeeId;
    if (employeeId != null) {
      final monthStr = DateFormat('MM-yyyy').format(_selectedMonth);
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchEmployeeDashboard(employeeId, monthStr);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
    _loadData();
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogsChart(List<dynamic> chartData) {
    if (chartData.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No daily logs recorded for this month.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      // Extract day number from date string (YYYY-MM-DD)
      final date = DateTime.tryParse(item.label);
      final day = date != null ? date.day : i + 1;

      final isPresent = item.present == 1;
      final isAbsent = item.absent == 1;
      final isLate = item.lateCount == 1; // mapped as late in backend chart

      double yVal = 0;
      Color barColor = Colors.grey[300]!;

      if (isPresent) {
        yVal = isLate ? 6.0 : 10.0;
        barColor = isLate ? const Color(0xFFF59E0B) : const Color(0xFF007F70);
      } else if (isAbsent) {
        yVal = 4.0;
        barColor = const Color(0xFFE15353);
      }

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: yVal == 0 ? 1.0 : yVal, // tiny bar if zero
              color: yVal == 0 ? Colors.grey[200]! : barColor,
              width: 5,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
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
          barGroups: barGroups,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final summary = dashboardProvider.employeeSummary;
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
          'My Workdesk',
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
                    // Month Picker Controller
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
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _changeMonth(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Attendance Summary',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (summary != null) ...[
                      // Responsive Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 900
                            ? 3
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: MediaQuery.of(context).size.width > 900
                            ? 3.2
                            : MediaQuery.of(context).size.width > 600
                                ? 2.5
                                : 2.1,
                        children: [
                          _buildStatCard(
                            label: 'Present Days',
                            value: summary.presentCount,
                            icon: Icons.check_circle_outline,
                            color: Colors.teal,
                          ),
                          _buildStatCard(
                            label: 'Late Clock-ins',
                            value: summary.lateCount,
                            icon: Icons.timer_outlined,
                            color: Colors.amber[800]!,
                          ),
                          _buildStatCard(
                            label: 'Short Leaves',
                            value: summary.shortLeaveCount,
                            icon: Icons.assignment_outlined,
                            color: Colors.purple[700]!,
                          ),
                          _buildStatCard(
                            label: 'Approved Leaves',
                            value: summary.leaveCount,
                            icon: Icons.calendar_today_outlined,
                            color: Colors.indigo,
                          ),
                          _buildStatCard(
                            label: 'Absent Days',
                            value: summary.absentCount,
                            icon: Icons.remove_circle_outline,
                            color: Colors.red[600]!,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Daily Logs Chart Card
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
                                    'Daily Status Log',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildLegendDot(Colors.teal, 'Present'),
                                      const SizedBox(width: 6),
                                      _buildLegendDot(Colors.amber[800]!, 'Late'),
                                      const SizedBox(width: 6),
                                      _buildLegendDot(Colors.red[600]!, 'Absent'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildDailyLogsChart(summary.chartData),
                            ],
                          ),
                        ),
                      ),
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
