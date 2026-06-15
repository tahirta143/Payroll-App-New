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
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final List<int> _history = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void changeTab(int index, {bool addToHistory = true}) {
    if (_currentIndex == index) return;
    setState(() {
      if (addToHistory) {
        _history.remove(index); // Remove existing instance to avoid duplicate cycles
        _history.add(_currentIndex);
      }
      _currentIndex = index;
      _bottomNavigationKey.currentState?.setPage(index);
    });
  }

  void changeTabByRoute(String routePath, {bool addToHistory = true}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tabs = _getTabs(authProvider);
    final index = tabs.indexWhere((tab) => tab.routePath == routePath);
    if (index != -1) {
      changeTab(index, addToHistory: addToHistory);
    }
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

    return PopScope(
      canPop: _currentIndex == 0 && _history.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_history.isNotEmpty) {
          final prevIndex = _history.removeLast();
          setState(() {
            _currentIndex = prevIndex;
            _bottomNavigationKey.currentState?.setPage(prevIndex);
          });
        } else {
          setState(() {
            _currentIndex = 0;
            _bottomNavigationKey.currentState?.setPage(0);
          });
        }
      },
      child: Scaffold(
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
            changeTab(index);
          },
        ),
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
