import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  ClassModel? _myClass;
  bool _isLoading = true;
  String? _error;
  bool _hasNoClass = false;
  int _totalStudents = 0;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchMyClass();
  }

  Future<void> _fetchMyClass() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasNoClass = false;
    });
    try {
      final classData = await ApiClient.get('/classes/my');
      final cls = ClassModel.fromJson(classData);
      final students = await ApiClient.get('/students/${cls.classId}');
      final activeStudents =
          (students as List).where((s) => s['is_active'] == true).length;
      setState(() {
        _myClass = cls;
        _totalStudents = activeStudents;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      // Detect "no class" specifically vs a real error
      final isNoClass = e.message.toLowerCase().contains('no class') ||
          e.message.toLowerCase().contains('not found') ||
          e.statusCode == 404;
      setState(() {
        _hasNoClass = isNoClass;
        _error = isNoClass ? null : e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _createClass(String name) async {
    if (name.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      await ApiClient.post('/classes/', {'name': name.trim()});
      await _fetchMyClass();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class "$name" created!'),
            backgroundColor: AppTheme.paidGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.unpaidRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showCreateClassDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Your Class'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Class Name',
            hintText: 'e.g. Nursery A, Class 5B…',
            prefixIcon: Icon(Icons.class_rounded),
          ),
          onSubmitted: (v) {
            Navigator.pop(ctx);
            _createClass(v);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createClass(ctrl.text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasNoClass
              ? _buildNoClassView()
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 64, color: AppTheme.unpaidRed),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed: _fetchMyClass,
                                child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyClass,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    AppTheme.staffPurple,
                                    Color(0xFF5B21B6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.staffPurple.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 40),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Welcome, Staff',
                                          style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                      Text(
                                        _myClass?.name ?? 'My Class',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$_totalStudents',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800)),
                                      Text('Students',
                                          style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stats
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Total Students',
                                    value: '$_totalStudents',
                                    icon: Icons.people_rounded,
                                    color: AppTheme.staffPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    title: 'My Class',
                                    value: _myClass?.name ?? '-',
                                    icon: Icons.class_rounded,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Text('Quick Actions',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 12),

                            // Action Grid
                            if (_myClass != null)
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.5,
                                children: [
                                  _QuickActionCard(
                                    title: 'Students',
                                    icon: Icons.people_rounded,
                                    color: AppTheme.primaryBlue,
                                    onTap: () => context.push(
                                        '/staff/students?classId=${_myClass!.classId}&name=${Uri.encodeComponent(_myClass!.name)}'),
                                  ),
                                  _QuickActionCard(
                                    title: 'Attendance',
                                    icon: Icons.fact_check_rounded,
                                    color: AppTheme.adminGreen,
                                    onTap: () => context.push(
                                        '/staff/attendance?classId=${_myClass!.classId}&name=${Uri.encodeComponent(_myClass!.name)}'),
                                  ),
                                  _QuickActionCard(
                                    title: 'Fees',
                                    icon: Icons.receipt_long_rounded,
                                    color: AppTheme.warningAmber,
                                    onTap: () => context.push(
                                        '/staff/fees?classId=${_myClass!.classId}&name=${Uri.encodeComponent(_myClass!.name)}'),
                                  ),
                                  _QuickActionCard(
                                    title: 'Van Fees',
                                    icon: Icons.directions_bus_rounded,
                                    color: AppTheme.staffPurple,
                                    onTap: () => context.push(
                                        '/staff/van-fees?classId=${_myClass!.classId}&name=${Uri.encodeComponent(_myClass!.name)}'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNoClassView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.staffPurple, Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.class_rounded,
                  size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'No Class Assigned Yet',
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t registered a class yet.\nCreate one to start managing students, fees & attendance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _creating ? null : _showCreateClassDialog,
              icon: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(_creating ? 'Creating…' : 'Create My Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.staffPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchMyClass,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
