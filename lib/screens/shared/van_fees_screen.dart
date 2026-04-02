import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/file_service.dart';
import '../../providers/auth_provider.dart';

class VanFeesScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool showAppBar;

  const VanFeesScreen({
    super.key,
    required this.classId,
    required this.className,
    this.showAppBar = true,
  });

  @override
  State<VanFeesScreen> createState() => _VanFeesScreenState();
}

class _VanFeesScreenState extends State<VanFeesScreen> {
  List<StudentVanFeeModel> _vanFees = [];
  ClassVanFeeSummary? _summary;
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
    _fetchVanFees();
  }

  @override
  void didUpdateWidget(covariant VanFeesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _fetchVanFees();
    }
  }

  Future<void> _fetchVanFees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/van-fees/${widget.classId}');
      if (!mounted) return;
      final classVanFees = ClassVanFeeResponse.fromJson(response);

      setState(() {
        _vanFees = classVanFees.students;
        _summary = classVanFees.summary;
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

  Future<void> _toggleVanFee(String studentId, int month) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ApiClient.patch('/van-fees/$studentId/$month?year=$_selectedYear');
      if (!mounted) return;
      await _fetchVanFees();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _updateAmount(String studentId, int month, double amount) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ApiClient.patch(
          '/van-fees/$studentId/$month/amount?year=$_selectedYear&amount=$amount');
      if (!mounted) return;
      await _fetchVanFees();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final fileName = 'van_fees_${widget.className}_$_selectedYear.pdf';
      final path =
          '/exports/van-fees/${widget.classId}/pdf?year=$_selectedYear';
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

  Future<void> _downloadExcel() async {
    try {
      final fileName = 'van_fees_${widget.className}_$_selectedYear.xlsx';
      final path =
          '/exports/van-fees/${widget.classId}/excel?year=$_selectedYear';
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
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('${widget.className} - Van Fees'),
              elevation: 0,
              actions: [
                IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    tooltip: 'Export PDF',
                    onPressed: _downloadPdf),
                IconButton(
                    icon: const Icon(Icons.table_chart_rounded),
                    tooltip: 'Export Excel',
                    onPressed: _downloadExcel),
                GestureDetector(
                  onTap: _showYearSelector,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('$_selectedYear',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue)),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppTheme.primaryBlue),
                    ]),
                  ),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                    Text('Van Fee Overview',
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
                      child: Text('${_vanFees.length} Students',
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
                            label: 'Total Fee',
                            value: '₹${totalExpected.toStringAsFixed(0)}',
                            icon: Icons.directions_bus_rounded)),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                        child: _StatItem(
                            label: 'Collected',
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
                    ? _buildError()
                    : _vanFees.isEmpty
                        ? const Center(child: Text('No Van Students Enrolled'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _vanFees.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final isAdmin = Provider.of<AuthProvider>(context,
                                      listen: false)
                                  .isAdmin;
                              return _VanFeeCard(
                                vanFee: _vanFees[i],
                                selectedYear: _selectedYear,
                                monthNames: _monthNames,
                                onToggle: isAdmin ? _toggleVanFee : null,
                                onUpdateAmount: isAdmin ? _updateAmount : null,
                                isToggling: _toggling,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showYearSelector() async {
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
                    onTap: () => Navigator.pop(ctx, y),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedYear = selected);
      _fetchVanFees();
    }
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppTheme.unpaidRed),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchVanFees, child: const Text('Retry')),
        ]),
      );
}

class _VanFeeCard extends StatelessWidget {
  final StudentVanFeeModel vanFee;
  final int selectedYear;
  final List<String> monthNames;
  final Function(String, int)? onToggle;
  final Function(String, int, double)? onUpdateAmount;
  final bool isToggling;

  const _VanFeeCard(
      {required this.vanFee,
      required this.selectedYear,
      required this.monthNames,
      required this.onToggle,
      required this.onUpdateAmount,
      required this.isToggling});

  void _showAmountDialog(BuildContext context, VanFeeRecord record) {
    final ctrl = TextEditingController(text: record.amount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Amount - ${monthNames[record.month - 1]}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Fee',
            prefixText: '₹',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && onUpdateAmount != null) {
                onUpdateAmount!(vanFee.studentId, record.month, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yearRecords = vanFee.vanRecords;
    final paidMonths = yearRecords.where((r) => r.isPaid).length;

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
          Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.staffPurple.withValues(alpha: 0.12),
              child: Text(
                vanFee.rollNo.isNotEmpty ? vanFee.rollNo : '?',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(vanFee.studentName,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$paidMonths / ${yearRecords.length} paid',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 6, 7, 8, 9, 10, 11, 0, 1, 2].map((idx) {
              final month = idx + 1;
              final record = yearRecords.firstWhere((r) => r.month == month,
                  orElse: () => VanFeeRecord(
                      month: month,
                      year: selectedYear,
                      status: 'unpaid',
                      amount: 0.0));
              final isPaid = record.isPaid;
              return GestureDetector(
                onTap: (isToggling || onToggle == null) ? null : () => onToggle!(vanFee.studentId, month),
                onLongPress: (isToggling || onUpdateAmount == null)
                    ? null
                    : () => _showAmountDialog(context, record),
                child: Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppTheme.paidGreen.withValues(alpha: 0.15)
                        : (isDark
                            ? AppTheme.darkCard
                            : AppTheme.lightBg),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isPaid
                            ? AppTheme.paidGreen
                            : (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder)),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(monthNames[idx],
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isPaid
                                    ? AppTheme.paidGreen
                                    : AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${record.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppTheme.paidGreen
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ]),
                ),
              );
            }).toList(),
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
