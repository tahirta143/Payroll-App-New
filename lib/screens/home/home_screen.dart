import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth/auth_provider.dart';
import '../../custom_widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm:ss A').format(now);
      _currentDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    });
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.grey[500],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final displayName = user?.name ?? user?.username ?? 'Employee';
    const tealColor = Color(0xFF007F70);

    final isEmployee = user?.employeeId != null;

    // Compile list of modules the user can access to show in the Grid
    final modules = <_HomeGridItem>[];

    if (auth.hasPermission('can-view-dashboard') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard',
        desc: 'Interactive operational stats and summaries.',
        color: Colors.indigo,
        onTap: () {
          // Switch to dashboard tab. (Tab index 1 in curved navigation)
          // Since it's nested in CurvedNavigationBar, we can pop or navigate
          // In a simple app, setting tab index or popping/pushing is easier.
          // For best native feel, we can just push the standalone screen if clicked from grid,
          // or navigate. Let's push screens for simple grid actions.
          Navigator.pushNamed(context, '/dashboard');
        },
      ));
    }

    if (auth.hasPermission('can-view-attendence') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.fingerprint_rounded,
        title: 'Attendance',
        desc: isEmployee ? 'View your personal attendance logs.' : 'Mark, edit, and review employee logs.',
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/attendance'),
      ));
    }

    if (auth.hasPermission('can-view-leave-application') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.calendar_month_outlined,
        title: 'Leaves Log',
        desc: isEmployee ? 'Track and apply for leaves.' : 'Track and manage leave applications.',
        color: Colors.amber[800]!,
        onTap: () => Navigator.pushNamed(context, '/leaves'),
      ));
    }

    if (auth.hasPermission('can-view-salary') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.monetization_on_outlined,
        title: 'Salary Slip',
        desc: isEmployee ? 'View your personal salary slip details.' : 'Configure basic payroll rates and bank accounts.',
        color: Colors.green[700]!,
        onTap: () => Navigator.pushNamed(context, '/salary'),
      ));
    }

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
          'Payroll Workspace',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: AppDrawer(activeRoute: '/home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header Card (styled similarly to React home-welcome gradient banner)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [tealColor, Color(0xFF51B5AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: tealColor.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HR Workspace',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hello $displayName,',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Welcome back to your payroll control center. Select a module below to get started.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xD9FFFFFF), // close to white/85
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Real-time Clock display
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _currentDate,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Modules section
            const Text(
              'Your Access',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${modules.length} modules available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Modules Grid
            modules.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Center(
                      child: Text(
                        'No workspace access permissions assigned. Contact your administrator.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final item = modules[index];
                      return _buildModuleCard(
                        icon: item.icon,
                        title: item.title,
                        desc: item.desc,
                        color: item.color,
                        onTap: item.onTap,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _HomeGridItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  _HomeGridItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });
}

// Custom color utility for white with 85% opacity
