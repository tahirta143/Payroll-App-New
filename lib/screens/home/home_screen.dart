import 'dart:async';
import 'package:analog_clock/analog_clock.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final displayName = user?.name ?? user?.username ?? 'Employee';
    final isEmployee = user?.employeeId != null;
    final role = isEmployee ? 'Employee' : 'Admin';
    const tealColor = Color(0xFF007F70);
    final size = MediaQuery.of(context).size;

    // Compile list of modules the user can access
    final List<_HomeGridItem> modules = [];

    if (auth.hasPermission('can-view-dashboard') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard',
        desc: 'Interactive operational stats and summaries.',
        color: Colors.indigo,
        onTap: () => Navigator.pushNamed(context, '/dashboard'),
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
        title: 'Leaves',
        desc: isEmployee ? 'Track and apply for leaves.' : 'Track and manage leave applications.',
        color: Colors.amber[800]!,
        onTap: () => Navigator.pushNamed(context, '/leaves'),
      ));
    }

    if (auth.hasPermission('can-view-salary') || isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.monetization_on_outlined,
        title: 'Salary',
        desc: isEmployee ? 'View your personal salary details.' : 'Configure basic payroll rates and bank accounts.',
        color: Colors.green[700]!,
        onTap: () => Navigator.pushNamed(context, '/salary'),
      ));
    }

    if (auth.hasPermission('can-view-salary-sheet-report') ||
        auth.hasPermission('can-view-salary-slip-report') ||
        isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.assessment_outlined,
        title: 'Salary Reports',
        desc: 'Generate monthly salary sheets and salary slips.',
        color: Colors.purple[700]!,
        onTap: () => Navigator.pushNamed(context, '/salary-reports'),
      ));
    }

    if (auth.hasPermission('can-view-leave-rules') || !isEmployee) {
      modules.add(_HomeGridItem(
        icon: Icons.rule_rounded,
        title: 'Leave Rules',
        desc: 'Configure leave entitlements and attendance rules.',
        color: Colors.blueGrey,
        onTap: () => Navigator.pushNamed(context, '/leave-rules'),
      ));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/home'),
      body: Stack(
        children: [
          // ── Scrollable Body ──
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spacer to push content below the fixed header and stat cards
                  SizedBox(
                    height: MediaQuery.of(context).orientation == Orientation.landscape
                        ? 260.0
                        : size.height * 0.42 + 40,
                  ),

                  // ── Modules Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Modules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                        Text(
                          '${modules.length} modules',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Modules Grid ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size.width > 900
                            ? 4
                            : size.width > 600
                                ? 3
                                : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: size.width > 900
                            ? 1.5
                            : size.width > 600
                                ? 1.35
                                : 1.22,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final item = modules[index];
                        return _buildModuleCard(item, index);
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ── Fixed Hero Header ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeroHeader(context, size, displayName, role, modules.length, tealColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, Size size, String user, String role, int modulesCount, Color tealColor) {
    final tp = MediaQuery.of(context).padding.top;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final headerHeight = isLandscape ? 220.0 : size.height * 0.42;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background banner
        Container(
          width: double.infinity,
          height: headerHeight,
          decoration: BoxDecoration(
            color: tealColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(35),
              bottomRight: Radius.circular(35),
            ),
          ),
        ),

        // Background decorative circles
        Positioned(
          top: -20,
          right: -40,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: 20,
          child: Container(
            width: size.width * 0.4,
            height: size.width * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),

        // Custom Top App Bar
        Positioned(
          top: tp + 12,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_rounded, color: Color(0xFF007F70), size: 22),
                ),
              ),
              const Text(
                "Home",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 44), // balance menu icon
            ],
          ),
        ),

        // Header Content Details
        Positioned(
          top: tp + 80,
          left: 24,
          right: 24,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _currentDate,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 155,
                height: 155,
                child: AnalogClock(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  isLive: true,
                  hourHandColor: Colors.white,
                  minuteHandColor: Colors.white,
                  secondHandColor: Colors.amberAccent,
                  showSecondHand: true,
                  numberColor: Colors.white,
                  showNumbers: true,
                  showAllNumbers: true,
                  showTicks: true,
                  showDigitalClock: false,
                  tickColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Overlapping Glassmorphism Stat Cards
        Positioned(
          bottom: -30,
          left: 20,
          right: 20,
          child: Row(
            children: [
              _buildStatCard(modulesCount.toString(), "Modules"),
              const SizedBox(width: 12),
              _buildStatCard("Online", "Status"),
              const SizedBox(width: 12),
              _buildStatCard("Active", "Session"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(_HomeGridItem card, int index) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDF2F7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Mono Index
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xFFCBD5E0),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007F70).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    card.icon,
                    size: 18,
                    color: const Color(0xFF007F70),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            // Tiny Arrow Indicator
            const Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.north_east_rounded,
                size: 12,
                color: Color(0xFFE2E8F0),
              ),
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
