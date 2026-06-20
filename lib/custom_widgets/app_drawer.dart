import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../screens/home/main_navigation_screen.dart';

class AppDrawer extends StatelessWidget {
  final String activeRoute;

  const AppDrawer({super.key, required this.activeRoute});

  String _getInitials(String name) {
    if (name.isEmpty) return 'HR';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'HR';
    return parts
        .take(2)
        .map((part) => part[0])
        .join('')
        .toUpperCase();
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routeName,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final tealColor = const Color(0xFF007F70);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isActive,
        selectedTileColor: tealColor.withAlpha(25),
        selectedColor: tealColor,
        leading: Icon(
          icon,
          color: isActive ? tealColor : Colors.grey[600],
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? tealColor : Colors.grey[800],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final displayName = user?.name ?? user?.username ?? 'User';
    final email = user?.email ?? 'No email added';
    final initials = _getInitials(displayName);
    final tealColor = const Color(0xFF007F70);

    final isEmployee = user?.employeeId != null;
    final mainNav = context.findAncestorStateOfType<MainNavigationScreenState>();

    void navigateToTab(String routeName) {
      Navigator.pop(context);
      if (mainNav != null) {
        mainNav.changeTabByRoute(routeName);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
      }
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header Card (Styled similarly to React Top Header Dropdown)
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              color: tealColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: tealColor.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: tealColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (user?.roleLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withAlpha(60)),
                          ),
                          child: Text(
                            user!.roleLabel!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.home_outlined,
                  label: 'Home',
                  routeName: '/home',
                  isActive: activeRoute == '/home',
                  onTap: () => navigateToTab('/home'),
                ),
                // Dashboard (Admin or Employee dashboard check)
                if (authProvider.hasPermission('can-view-dashboard') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    routeName: '/dashboard',
                    isActive: activeRoute == '/dashboard',
                    onTap: () => navigateToTab('/dashboard'),
                  ),
                // Attendance System
                if (authProvider.hasPermission('can-view-attendence') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.fingerprint,
                    label: 'Attendance',
                    routeName: '/attendance',
                    isActive: activeRoute == '/attendance',
                    onTap: () => navigateToTab('/attendance'),
                  ),
                // Leave applications
                if (authProvider.hasPermission('can-view-leave-application') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Leaves Log',
                    routeName: '/leaves',
                    isActive: activeRoute == '/leaves',
                    onTap: () => navigateToTab('/leaves'),
                  ),
                // Short Leaves
                if (authProvider.hasPermission('can-view-short-leaves') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.alarm_on_outlined,
                    label: 'Short Leaves',
                    routeName: '/short-leaves',
                    isActive: activeRoute == '/short-leaves',
                    onTap: () => navigateToTab('/short-leaves'),
                  ),
                // Payroll Salaries
                if (authProvider.hasPermission('can-view-salary') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.monetization_on_outlined,
                    label: isEmployee ? 'Salary Slip' : 'Salary Management',
                    routeName: '/salary',
                    isActive: activeRoute == '/salary',
                    onTap: () => navigateToTab('/salary'),
                  ),
                // Salary Reports Screen
                if (authProvider.hasPermission('can-view-salary-sheet-report') ||
                    authProvider.hasPermission('can-view-salary-slip-report') ||
                    isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.assessment_outlined,
                    label: 'Salary Reports',
                    routeName: '/salary-reports',
                    isActive: activeRoute == '/salary-reports',
                    onTap: () {
                      Navigator.pop(context);
                      if (activeRoute != '/salary-reports') {
                        Navigator.pushNamed(context, '/salary-reports');
                      }
                    },
                  ),
                // Leave Rules Config (Admin only)
                if (authProvider.hasPermission('can-view-attendence') && !isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    label: 'Leave Rules',
                    routeName: '/leave-rules',
                    isActive: activeRoute == '/leave-rules',
                    onTap: () {
                      Navigator.pop(context);
                      if (activeRoute != '/leave-rules') {
                        Navigator.pushNamed(context, '/leave-rules');
                      }
                    },
                  ),
              ],
            ),
          ),

          // Drawer Footer Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[100]!),
              ),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Logout Session',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
