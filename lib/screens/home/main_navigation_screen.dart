import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../../providers/auth/auth_provider.dart';
import '../../custom_widgets/app_drawer.dart';

// Import all screens we will display in tabs
import 'home_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../dashboard/employee_dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../leaves/leaves_screen.dart';
import '../leaves/short_leaves_screen.dart';
import '../salary/salary_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Helper descriptor class for tabs
  List<_NavigationTab> _getTabs(AuthProvider auth) {
    final tabs = <_NavigationTab>[];

    // 1. Home (Always visible)
    tabs.add(_NavigationTab(
      label: 'Home',
      icon: Icons.home_outlined,
      page: const HomeScreen(),
      routePath: '/home',
    ));

    // 2. Dashboard (If permitted OR if employee user)
    final isEmployee = auth.user?.employeeId != null;
    if (auth.hasPermission('can-view-dashboard') || isEmployee) {
      tabs.add(_NavigationTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: isEmployee
            ? const EmployeeDashboardScreen()
            : const AdminDashboardScreen(),
        routePath: '/dashboard',
      ));
    }

    // 3. Attendance (If permitted OR if employee user)
    if (auth.hasPermission('can-view-attendence') || isEmployee) {
      tabs.add(_NavigationTab(
        label: 'Attendance',
        icon: Icons.fingerprint_rounded,
        page: const AttendanceScreen(),
        routePath: '/attendance',
      ));
    }

    // 4. Leaves (If permitted OR if employee user)
    if (auth.hasPermission('can-view-leave-application') || isEmployee) {
      tabs.add(_NavigationTab(
        label: 'Leaves',
        icon: Icons.calendar_month_outlined,
        page: const LeavesScreen(),
        routePath: '/leaves',
      ));
    }

    // 5. Short Leaves (If permitted OR if employee user)
    if (auth.hasPermission('can-view-short-leaves') || isEmployee) {
      tabs.add(_NavigationTab(
        label: 'Short Leaves',
        icon: Icons.alarm_on_outlined,
        page: const ShortLeavesScreen(),
        routePath: '/short-leaves',
      ));
    }

    // 6. Salary (If permitted OR if employee user)
    if (auth.hasPermission('can-view-salary') || isEmployee) {
      tabs.add(_NavigationTab(
        label: 'Salary',
        icon: Icons.monetization_on_outlined,
        page: const SalaryScreen(),
        routePath: '/salary',
      ));
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tabs = _getTabs(authProvider);

    // Safeguard index out of bounds if permissions change on-the-fly
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    final activeTab = tabs[_currentIndex];
    const tealColor = Color(0xFF007F70);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: activeTab.routePath),
      body: activeTab.page,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _currentIndex,
        height: 58.0,
        items: tabs.map((tab) {
          final isSelected = tabs.indexOf(tab) == _currentIndex;
          return Icon(
            tab.icon,
            size: 24,
            color: isSelected ? Colors.white : Colors.grey[600],
          );
        }).toList(),
        color: Colors.white,
        buttonBackgroundColor: tealColor,
        backgroundColor: const Color(0xFFF8F9FA),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _NavigationTab {
  final String label;
  final IconData icon;
  final Widget page;
  final String routePath;

  _NavigationTab({
    required this.label,
    required this.icon,
    required this.page,
    required this.routePath,
  });
}
