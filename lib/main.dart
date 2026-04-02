import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';

import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/staff_management_screen.dart';
import 'screens/admin/salary_screen.dart';
import 'screens/shared/students_screen.dart';
import 'screens/shared/fees_screen.dart';
import 'screens/shared/van_fees_screen.dart';
import 'screens/shared/attendance_module_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SchoolManagementApp(),
    ),
  );
}

class SchoolManagementApp extends StatefulWidget {
  const SchoolManagementApp({super.key});

  @override
  State<SchoolManagementApp> createState() => _SchoolManagementAppState();
}

class _SchoolManagementAppState extends State<SchoolManagementApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoginPage = state.matchedLocation == '/login';
        final isSplashPage = state.matchedLocation == '/splash';

        // Always allow Splash Screen to show its animation
        if (isSplashPage) return null;

        // If not logged in and not heading to login (or splash), force login
        if (!isLoggedIn && !isLoginPage) return '/login';

        // Role-based Path Protection
        if (isLoggedIn) {
          final isAdminPath = state.matchedLocation.startsWith('/admin');
          final isStaffPath = state.matchedLocation.startsWith('/staff');

          if (isAdminPath && !authProvider.isAdmin) return '/staff';
          if (isStaffPath && authProvider.isAdmin) return '/admin';
          if (isLoginPage) return authProvider.isAdmin ? '/admin' : '/staff';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (ctx, _) => const SplashScreen()),
        GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),

        // Admin Routes
        GoRoute(path: '/admin', builder: (ctx, _) => const AdminDashboard()),
        GoRoute(
            path: '/admin/students/:classId',
            builder: (ctx, state) {
              final classId = state.pathParameters['classId']!;
              final className = state.uri.queryParameters['name'] ?? 'Class';
              return StudentsScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/admin/fees/:classId',
            builder: (ctx, state) {
              final classId = state.pathParameters['classId']!;
              final className = state.uri.queryParameters['name'] ?? 'Class';
              return FeesScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/admin/van-fees/:classId',
            builder: (ctx, state) {
              final classId = state.pathParameters['classId']!;
              final className = state.uri.queryParameters['name'] ?? 'Class';
              return VanFeesScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/admin/attendance/:classId',
            builder: (ctx, state) {
              final classId = state.pathParameters['classId']!;
              final className = state.uri.queryParameters['name'] ?? 'Class';
              return AttendanceModuleScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/admin/staff',
            builder: (ctx, _) => const StaffManagementScreen()),
        GoRoute(
            path: '/admin/salary', builder: (ctx, _) => const SalaryScreen()),

        // Staff Routes
        GoRoute(path: '/staff', builder: (ctx, _) => const StaffDashboard()),
        GoRoute(
            path: '/staff/students',
            builder: (ctx, state) {
              final classId = state.uri.queryParameters['classId'] ?? '';
              final className = state.uri.queryParameters['name'] ?? 'My Class';
              return StudentsScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/staff/fees',
            builder: (ctx, state) {
              final classId = state.uri.queryParameters['classId'] ?? '';
              final className = state.uri.queryParameters['name'] ?? 'My Class';
              return FeesScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/staff/van-fees',
            builder: (ctx, state) {
              final classId = state.uri.queryParameters['classId'] ?? '';
              final className = state.uri.queryParameters['name'] ?? 'My Class';
              return VanFeesScreen(classId: classId, className: className);
            }),
        GoRoute(
            path: '/staff/attendance',
            builder: (ctx, state) {
              final classId = state.uri.queryParameters['classId'] ?? '';
              final className = state.uri.queryParameters['name'] ?? 'My Class';
              return AttendanceModuleScreen(classId: classId, className: className, showBackButton: false);
            }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'School Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
