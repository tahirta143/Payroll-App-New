import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers imports
import 'providers/auth/auth_provider.dart';
import 'providers/dashboard/dashboard_provider.dart';
import 'providers/attendance/attendance_provider.dart';
import 'providers/attendance/attendance_sheet_provider.dart';
import 'providers/salary/salary_provider.dart';
import 'providers/salary/salary_report_provider.dart';
import 'providers/leaves/leave_provider.dart';
import 'providers/leaves/short_leave_provider.dart';
import 'providers/leaves/leave_rules_provider.dart';

// Screens imports
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/employees/employees_screen.dart';
import 'screens/attendance/absents_screen.dart';
import 'screens/attendance/today_attendance_screen.dart';
import 'screens/reports/salary_report_screen.dart';
import 'screens/reports/attendance_sheet_screen.dart';
import 'screens/leaves/leave_rules_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF007F70);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceSheetProvider()),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => SalaryReportProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => ShortLeaveProvider()),
        ChangeNotifierProvider(create: (_) => LeaveRulesProvider()),
      ],
      child: MaterialApp(
        title: 'Payroll App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: tealColor,
            primary: tealColor,
            surfaceTint: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: tealColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/nav': (context) => const MainNavigationScreen(initialIndex: 0),
          
          // Drawer and Home grid index mapping
          '/home': (context) => const MainNavigationScreen(initialIndex: 0),
          '/dashboard': (context) => const MainNavigationScreen(initialIndex: 1),
          '/attendance': (context) => const MainNavigationScreen(initialIndex: 2),
          '/leaves': (context) => const MainNavigationScreen(initialIndex: 3),
          '/short-leaves': (context) => const MainNavigationScreen(initialIndex: 4),
          '/salary': (context) => const MainNavigationScreen(initialIndex: 5),
          '/salary-reports': (context) => const SalaryReportScreen(),
          '/attendance-sheet': (context) => const AttendanceSheetScreen(),
          '/leave-rules': (context) => const LeaveRulesScreen(),

          // Details routes
          '/employees-list': (context) => const EmployeesScreen(),
          '/absents': (context) => const AbsentsScreen(),
          '/today-attendance': (context) => const TodayAttendanceScreen(),
        },
      ),
    );
  }
}
