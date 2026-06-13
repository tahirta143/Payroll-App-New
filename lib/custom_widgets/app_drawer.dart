import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';

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
        selectedTileColor: tealColor.withOpacity(0.1),
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

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header Card (Styled similarly to React Top Header Dropdown)
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[100]!),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: tealColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (user?.roleLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tealColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user!.roleLabel!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: tealColor,
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                // Dashboard (Admin or Employee dashboard check)
                if (authProvider.hasPermission('can-view-dashboard') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    routeName: '/dashboard',
                    isActive: activeRoute == '/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                  ),
                // Attendance System
                if (authProvider.hasPermission('can-view-attendence') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.fingerprint,
                    label: 'Attendance',
                    routeName: '/attendance',
                    isActive: activeRoute == '/attendance',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/attendance');
                    },
                  ),
                // Leave applications
                if (authProvider.hasPermission('can-view-leave-application') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Leaves Log',
                    routeName: '/leaves',
                    isActive: activeRoute == '/leaves',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/leaves');
                    },
                  ),
                // Short Leaves
                if (authProvider.hasPermission('can-view-short-leaves') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.alarm_on_outlined,
                    label: 'Short Leaves',
                    routeName: '/short-leaves',
                    isActive: activeRoute == '/short-leaves',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/short-leaves');
                    },
                  ),
                // Payroll Salaries
                if (authProvider.hasPermission('can-view-salary') || isEmployee)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.monetization_on_outlined,
                    label: isEmployee ? 'Salary Slip' : 'Salary Management',
                    routeName: '/salary',
                    isActive: activeRoute == '/salary',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/salary');
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
