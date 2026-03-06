import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../api/api_client.dart';
import '../../services/file_service.dart';

class StaffSettingsScreen extends StatelessWidget {
  final String classId;
  final VoidCallback? onRefresh;
  const StaffSettingsScreen({super.key, required this.classId, this.onRefresh});

  void _clearLocalData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
            'This will clear all student data cached on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: Implement actual database clearing logic when local DB is added
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local cache cleared!')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editClassName(BuildContext context) async {
    final ctrl = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Class Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'New Class Name',
            hintText: 'e.g. Class 10A',
            prefixIcon: Icon(Icons.class_rounded),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      await ApiClient.put('/classes/', {'name': newName.trim()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class renamed to "$newName"!'),
            backgroundColor: AppTheme.paidGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onRefresh?.call();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.unpaidRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteClass(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text(
            'This will permanently delete this class and all associated students, attendance, and fee records. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('/classes/');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: AppTheme.unpaidRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onRefresh?.call();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.unpaidRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (classId.isEmpty) return;
    try {
      final now = DateTime.now();
      final fileName = 'attendance_${classId}_${now.year}_${now.month}.pdf';
      final path = '/exports/attendance/$classId/${now.year}/${now.month}/pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Generating PDF...'), duration: Duration(seconds: 2)),
      );

      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (classId.isEmpty) return;
    try {
      final now = DateTime.now();
      final fileName = 'attendance_${classId}_${now.year}_${now.month}.xlsx';
      final path =
          '/exports/attendance/$classId/${now.year}/${now.month}/excel';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Generating Excel...'),
            duration: Duration(seconds: 2)),
      );

      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.staffPurple, Color(0xFF6B21A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff Settings',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text('Manage data and exports',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Class Management',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (classId.isNotEmpty) ...[
            _SettingsItem(
              icon: Icons.edit_note_rounded,
              title: 'Edit Class Name',
              subtitle: 'Update your official class designation',
              onTap: () => _editClassName(context),
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.delete_forever_rounded,
              title: 'Delete My Class',
              subtitle: 'Permanently remove class and all data',
              iconColor: Colors.red,
              onTap: () => _deleteClass(context),
            ),
            const SizedBox(height: 24),
          ],

          Text('Data Management',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear Local Student Data',
            subtitle: 'Recommended before starting a new session',
            onTap: () => _clearLocalData(context),
          ),

          const SizedBox(height: 24),
          Text('Exports', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export My Monthly Attendance (PDF)',
            subtitle: 'Attendance report for current month',
            onTap: () => _exportPdf(context),
          ),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.table_chart_outlined,
            title: 'Export My Monthly Attendance (Excel)',
            subtitle: 'Attendance report for current month',
            onTap: () => _exportExcel(context),
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.unpaidRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.staffPurple).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.staffPurple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
