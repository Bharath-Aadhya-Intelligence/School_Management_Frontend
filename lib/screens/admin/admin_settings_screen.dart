import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../services/file_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  bool _isLoadingClasses = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final data = await ApiClient.get('/classes/');
      if (!mounted) return;
      setState(() {
        _classes = (data as List).map((e) => ClassModel.fromJson(e)).toList();
        if (_classes.isNotEmpty) _selectedClass = _classes.first;
        _isLoadingClasses = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedClass == null) return;
    try {
      final fileName = 'fee_report_${_selectedClass!.name}.pdf';
      final path = '/exports/fees/${_selectedClass!.classId}/pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_selectedClass == null) return;
    try {
      final fileName = 'fee_report_${_selectedClass!.name}.xlsx';
      final path = '/exports/fees/${_selectedClass!.classId}/excel';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating Excel...')),
      );

      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
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
                    Text('Admin Settings',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text('Manage exports and session',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight,
              ),
            ),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Row(
                  children: [
                    _buildThemeOption(
                      context,
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_rounded,
                      label: 'Light',
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    _buildThemeOption(
                      context,
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark',
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                    _buildThemeOption(
                      context,
                      mode: ThemeMode.system,
                      icon: Icons.settings_brightness_rounded,
                      label: 'System',
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Text('Class Selection',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Select a class for fee exports',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),

          if (_isLoadingClasses)
            const Center(child: CircularProgressIndicator())
          else if (_classes.isEmpty)
            const Text('No classes found.')
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkBorder
                      : AppTheme.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ClassModel>(
                  value: _selectedClass,
                  isExpanded: true,
                  items: _classes
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedClass = val),
                ),
              ),
            ),

          const SizedBox(height: 24),
          Text('Exports', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Student Fee Status (PDF)',
            subtitle: 'Paid and Pending installments',
            onTap: _exportPdf,
          ),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.table_chart_outlined,
            title: 'Export Student Fee Status (Excel)',
            subtitle: 'Paid and Pending installments',
            onTap: _exportExcel,
          ),

          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isLoggingOut 
              ? null 
              : () async {
                  setState(() => _isLoggingOut = true);
                  try {
                    await auth.logout();
                  } finally {
                    if (mounted) setState(() => _isLoggingOut = false);
                  }
                },
            icon: _isLoggingOut 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Icon(Icons.logout_rounded),
            label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
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

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue),
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
