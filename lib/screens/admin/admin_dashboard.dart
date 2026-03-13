import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import 'admin_settings_screen.dart';
import 'staff_management_screen.dart';
import 'salary_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _AdminHomeView(
            onActionTap: (index) => setState(() => _currentIndex = index),
          ),
          const SafeArea(child: StaffManagementScreen()),
          const SafeArea(child: SalaryScreen()),
          const SafeArea(child: AdminSettingsScreen()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Staff',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments_rounded),
              label: 'Salary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeView extends StatefulWidget {
  final Function(int) onActionTap;
  const _AdminHomeView({required this.onActionTap});

  @override
  State<_AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<_AdminHomeView> {
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/classes/');
      if (!mounted) return;
      setState(() {
        _classes = (data as List).map((e) => ClassModel.fromJson(e)).toList();
        _classes.sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Staff Management',
            onPressed: () => widget.onActionTap(1),
          ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Salary',
            onPressed: () => widget.onActionTap(2),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchClasses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _fetchClasses)
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Banner
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryBlueDark
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.primaryBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        color: Colors.white,
                                        size: 40),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Welcome, Admin',
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 13)),
                                        Text('School Dashboard',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_classes.length}',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        Text('Classes',
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Total Classes',
                                      value: '${_classes.length}',
                                      icon: Icons.class_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Quick Links',
                                      value: 'Staff & Salary',
                                      icon: Icons.people_rounded,
                                      color: AppTheme.adminGreen,
                                      onTap: () => widget.onActionTap(1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'All Classes',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select a class to manage students, fees & attendance',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _ClassCard(cls: _classes[i]),
                            childCount: _classes.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel cls;
  const _ClassCard({required this.cls});

  static const _gradients = [
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFFDC2626), Color(0xFFB91C1C)],
    [Color(0xFF0891B2), Color(0xFF0E7490)],
  ];

  @override
  Widget build(BuildContext context) {
    final colorPair = _gradients[cls.name.hashCode.abs() % _gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colorPair,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.class_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(cls.name,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(cls.staffEmail,
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          // Action Buttons Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'Students',
                  icon: Icons.people_rounded,
                  onTap: () => context.push(
                      '/admin/students/${cls.classId}?name=${Uri.encodeComponent(cls.name)}'),
                ),
                _ActionChip(
                  label: 'Fees',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => context.push(
                      '/admin/fees/${cls.classId}?name=${Uri.encodeComponent(cls.name)}'),
                ),
                _ActionChip(
                  label: 'Van Fees',
                  icon: Icons.directions_bus_rounded,
                  onTap: () => context.push(
                      '/admin/van-fees/${cls.classId}?name=${Uri.encodeComponent(cls.name)}'),
                ),
                _ActionChip(
                  label: 'Attendance',
                  icon: Icons.fact_check_rounded,
                  onTap: () => context.push(
                      '/admin/attendance/${cls.classId}?name=${Uri.encodeComponent(cls.name)}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.unpaidRed),
            const SizedBox(height: 16),
            Text(error,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
