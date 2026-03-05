import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  List<StaffSalaryModel> _salaries = [];
  bool _isLoading = true;
  String? _error;
  int _selectedYear = DateTime.now().year;
  bool _toggling = false;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSalaries();
  }

  Future<void> _fetchSalaries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/salary/');
      setState(() {
        _salaries =
            (data as List).map((e) => StaffSalaryModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSalary(String staffId, int month) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ApiClient.patch('/salary/$staffId/$month/$_selectedYear');
      await _fetchSalaries();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _initSalary(String staffId) async {
    try {
      await ApiClient.post('/salary/init/$staffId/$_selectedYear', {});
      _fetchSalaries();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Salary records initialized'),
            backgroundColor: AppTheme.paidGreen));
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Salary'),
        actions: [
          // Year selector
          GestureDetector(
            onTap: () async {
              final years = [
                DateTime.now().year - 1,
                DateTime.now().year,
                DateTime.now().year + 1
              ];
              final selected = await showDialog<int>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Select Year'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: years
                        .map((y) => ListTile(
                              title: Text('$y'),
                              selected: y == _selectedYear,
                              selectedColor: AppTheme.primaryBlue,
                              onTap: () => Navigator.pop(ctx, y),
                            ))
                        .toList(),
                  ),
                ),
              );
              if (selected != null) {
                setState(() => _selectedYear = selected);
                _fetchSalaries();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$_selectedYear',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppTheme.primaryBlue),
              ]),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Downloading PDF...'),
                    backgroundColor: AppTheme.primaryBlue));
              }),
          IconButton(
              icon: const Icon(Icons.table_chart_rounded),
              tooltip: 'Export Excel',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Downloading Excel...'),
                    backgroundColor: AppTheme.primaryBlue));
              }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: AppTheme.unpaidRed),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _fetchSalaries, child: const Text('Retry')),
                ]))
              : _salaries.isEmpty
                  ? const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No Salary Records',
                      subtitle: 'Add staff members first to track salaries')
                  : RefreshIndicator(
                      onRefresh: _fetchSalaries,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _salaries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _SalaryCard(
                          salary: _salaries[i],
                          selectedYear: _selectedYear,
                          monthNames: _monthNames,
                          onToggle: _toggleSalary,
                          onInit: _initSalary,
                          isToggling: _toggling,
                        ),
                      ),
                    ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final StaffSalaryModel salary;
  final int selectedYear;
  final List<String> monthNames;
  final Function(String, int) onToggle;
  final Function(String) onInit;
  final bool isToggling;

  const _SalaryCard({
    required this.salary,
    required this.selectedYear,
    required this.monthNames,
    required this.onToggle,
    required this.onInit,
    required this.isToggling,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yearRecords =
        salary.records.where((r) => r.year == selectedYear).toList();
    final paidCount = yearRecords.where((r) => r.isPaid).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Info Header
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.adminGreen, Color(0xFF047857)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(
                salary.staffName[0].toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(salary.staffName,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(salary.designation,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '₹${salary.monthlySalary.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.paidGreen),
              ),
              Text('$paidCount/12 months',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 12),

          // Month Grid
          if (yearRecords.isEmpty)
            ElevatedButton.icon(
              onPressed: () => onInit(salary.staffId),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text('Init Salary for $selectedYear'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size.fromHeight(40)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(12, (idx) {
                final month = idx + 1;
                final record = yearRecords.firstWhere(
                  (r) => r.month == month,
                  orElse: () => SalaryRecord(
                      month: month, year: selectedYear, status: 'not_paid'),
                );
                final isPaid = record.isPaid;
                return GestureDetector(
                  onTap:
                      isToggling ? null : () => onToggle(salary.staffId, month),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.paidGreen.withOpacity(0.12)
                          : (isDark
                              ? AppTheme.darkSurface
                              : AppTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid
                            ? AppTheme.paidGreen
                            : (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.borderLight),
                        width: isPaid ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthNames[idx],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPaid
                                  ? AppTheme.paidGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          Icon(
                            isPaid ? Icons.check_rounded : Icons.remove_rounded,
                            size: 14,
                            color: isPaid
                                ? AppTheme.paidGreen
                                : AppTheme.textSecondary,
                          ),
                        ]),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
