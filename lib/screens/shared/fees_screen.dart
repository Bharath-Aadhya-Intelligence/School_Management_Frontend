import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class FeesScreen extends StatefulWidget {
  final String classId;
  final String className;
  const FeesScreen({super.key, required this.classId, required this.className});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  List<StudentFeeModel> _fees = [];
  bool _isLoading = true;
  String? _error;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _fetchFees();
  }

  Future<void> _fetchFees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/fees/${widget.classId}');
      setState(() {
        _fees = (data as List).map((e) => StudentFeeModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _initFees() async {
    try {
      await ApiClient.post('/fees/init/${widget.classId}', {});
      _fetchFees();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fee records initialized'),
            backgroundColor: AppTheme.paidGreen));
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
    }
  }

  Future<void> _toggleFee(String studentId, int installmentNo) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ApiClient.patch('/fees/$studentId/$installmentNo');
      await _fetchFees();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Downloading PDF report...'),
          backgroundColor: AppTheme.primaryBlue),
    );
  }

  void _downloadExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Downloading Excel report...'),
          backgroundColor: AppTheme.primaryBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate collection stats
    int totalInstallments = _fees.length * 4;
    int paidInstallments = _fees.fold(0, (sum, f) => sum + f.paidCount);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className,
                style: Theme.of(context).textTheme.titleLarge),
            Text('Fee Management',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _downloadPdf),
          IconButton(
              icon: const Icon(Icons.table_chart_rounded),
              tooltip: 'Export Excel',
              onPressed: _downloadExcel),
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _fetchFees),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // Stats Banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                                label: 'Students',
                                value: '${_fees.length}',
                                icon: Icons.people_rounded),
                          ),
                          Container(
                              width: 1, height: 40, color: Colors.white24),
                          Expanded(
                            child: _StatItem(
                                label: 'Paid',
                                value: '$paidInstallments',
                                icon: Icons.check_circle_rounded),
                          ),
                          Container(
                              width: 1, height: 40, color: Colors.white24),
                          Expanded(
                            child: _StatItem(
                                label: 'Pending',
                                value:
                                    '${totalInstallments - paidInstallments}',
                                icon: Icons.pending_rounded),
                          ),
                        ],
                      ),
                    ),

                    // Init Button if empty
                    if (_fees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: _initFees,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Initialize Fee Records'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.adminGreen,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),

                    // Fee List
                    Expanded(
                      child: _fees.isEmpty
                          ? EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No Fee Records',
                              subtitle:
                                  'Click Initialize to create fee records for all students',
                              action: ElevatedButton(
                                  onPressed: _initFees,
                                  child: const Text('Initialize Fees')),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _fees.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) => _FeeCard(
                                fee: _fees[i],
                                onToggle: _toggleFee,
                                isToggling: _toggling,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppTheme.unpaidRed),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchFees, child: const Text('Retry')),
        ]),
      );
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
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _FeeCard extends StatelessWidget {
  final StudentFeeModel fee;
  final Function(String, int) onToggle;
  final bool isToggling;

  const _FeeCard(
      {required this.fee, required this.onToggle, required this.isToggling});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(fee.studentName,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            StatusBadge(
              status: fee.paidCount == 4 ? 'paid' : 'unpaid',
              paidLabel: 'All Paid',
              unpaidLabel: '${fee.paidCount}/4 Paid',
            ),
          ]),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (idx) {
              final inst = fee.installments.firstWhere(
                  (i) => i.installmentNo == idx + 1,
                  orElse: () =>
                      FeeInstallment(installmentNo: idx + 1, status: 'unpaid'));
              final isPaid = inst.isPaid;
              return Expanded(
                child: GestureDetector(
                  onTap: isToggling
                      ? null
                      : () => onToggle(fee.studentId, idx + 1),
                  child: Container(
                    margin: EdgeInsets.only(right: idx < 3 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.paidGreen.withOpacity(0.12)
                          : AppTheme.unpaidRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid
                            ? AppTheme.paidGreen.withOpacity(0.4)
                            : AppTheme.unpaidRed.withOpacity(0.2),
                      ),
                    ),
                    child: Column(children: [
                      Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isPaid
                            ? AppTheme.paidGreen
                            : AppTheme.unpaidRed.withOpacity(0.5),
                      ),
                      const SizedBox(height: 2),
                      Text('Q${idx + 1}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPaid
                                  ? AppTheme.paidGreen
                                  : AppTheme.textSecondary)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
