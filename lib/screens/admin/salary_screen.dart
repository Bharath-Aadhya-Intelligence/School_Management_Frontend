import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/file_service.dart';
import '../../widgets/empty_state.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  List<StaffSalaryModel> _salaries = [];
  YearlySalarySummary? _summary;
  bool _isLoading = true;
  String? _error;
  int _selectedYear = DateTime.now().year;
  bool _toggling = false;

  static const _monthNames = [
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
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
      final response = await ApiClient.get('/salary/$_selectedYear');
      if (!mounted) return;
      final salaryResponse = YearlySalaryResponse.fromJson(response);
      setState(() {
        _salaries = salaryResponse.staffRecords;
        _summary = salaryResponse.summary;
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
      if (!mounted) return;
      await _fetchSalaries();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _initSalary(String staffId) async {
    try {
      await ApiClient.post('/salary/init/$staffId/$_selectedYear', {});
      if (!mounted) return;
      _fetchSalaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Salary records initialized'),
            backgroundColor: AppTheme.paidGreen));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final fileName = 'staff_salary_$_selectedYear.pdf';
      final path = '/exports/salary/pdf?year=$_selectedYear';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      final fileName = 'staff_salary_$_selectedYear.xlsx';
      final path = '/exports/salary/excel?year=$_selectedYear';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Generating Excel...')));
      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalExpected = _summary?.totalExpected ?? 0.0;
    double totalPaid = _summary?.totalPaid ?? 0.0;
    double balance = _summary?.balance ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Salary'),
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _exportPdf),
          IconButton(
              icon: const Icon(Icons.table_chart_rounded),
              tooltip: 'Export Excel',
              onPressed: _exportExcel),
          // Year selector
          GestureDetector(
            onTap: () async {
              final selectedDate = await showDialog<DateTime>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Select Year"),
                    content: SizedBox(
                      width: 300,
                      height: 300,
                      child: YearPicker(
                        firstDate: DateTime(DateTime.now().year - 20),
                        lastDate: DateTime(DateTime.now().year + 10),
                        selectedDate: DateTime(_selectedYear),
                        onChanged: (DateTime dateTime) {
                          Navigator.pop(context, dateTime);
                        },
                      ),
                    ),
                  );
                },
              );
              if (selectedDate != null) {
                setState(() => _selectedYear = selectedDate.year);
                _fetchSalaries();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
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
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Salary Overview ($_selectedYear)',
                        style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${_salaries.length} Staff Members',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _StatItem(
                            label: 'Expected',
                            value: '₹${totalExpected.toStringAsFixed(0)}',
                            icon: Icons.payments_rounded)),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                        child: _StatItem(
                            label: 'Paid',
                            value: '₹${totalPaid.toStringAsFixed(0)}',
                            icon: Icons.check_circle_rounded)),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                        child: _StatItem(
                            label: 'Balance',
                            value: '₹${balance.toStringAsFixed(0)}',
                            icon: Icons.pending_rounded)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 64, color: AppTheme.unpaidRed),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _fetchSalaries,
                            child: const Text('Retry')),
                      ]))
                    : _salaries.isEmpty
                        ? const EmptyState(
                            icon: Icons.payments_outlined,
                            title: 'No Salary Records',
                            subtitle:
                                'Add staff members first to track salaries')
                        : RefreshIndicator(
                            onRefresh: _fetchSalaries,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _salaries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
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
          ),
        ],
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
                          ? AppTheme.paidGreen.withValues(alpha: 0.12)
                          : (isDark ? AppTheme.darkCard : AppTheme.lightBg),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      Text(label,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
    ]);
  }
}
