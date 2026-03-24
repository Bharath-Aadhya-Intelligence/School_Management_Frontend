import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/sort_utils.dart';
import '../../services/file_service.dart';

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
  bool _processing = false;

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
      final response = await ApiClient.get('/fees/${widget.classId}');
      if (!mounted) return;
      final feeList = (response as List)
          .map((json) => StudentFeeModel.fromJson(json))
          .toList();
      feeList.sort((a, b) => SortUtils.compareNatural(a.rollNo, b.rollNo));

      setState(() {
        _fees = feeList;
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

  Future<void> _initFees() async {
    try {
      await ApiClient.post('/fees/init/${widget.classId}', {});
      if (!mounted) return;
      _fetchFees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fee records initialized (3 Installments)'),
            backgroundColor: AppTheme.paidGreen));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    }
  }

  Future<void> _updatePayment(String studentId, int installmentNo, double amount) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await ApiClient.patch('/fees/$studentId/$installmentNo', body: {
        'amount_paid': amount,
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
      if (!mounted) return;
      await _fetchFees();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment updated successfully'),
          backgroundColor: AppTheme.paidGreen));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _downloadReceipt(String studentId, int installmentNo) async {
    try {
      final fileName = 'receipt_${studentId.substring(0, 4)}_inst$installmentNo.pdf';
      final path = '/exports/receipt/$studentId/$installmentNo';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Downloading Receipt...')));
      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Receipt download failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _downloadPdf() async {
    try {
      final fileName = 'fees_${widget.className}.pdf';
      final path = '/exports/fees/${widget.classId}/pdf';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _downloadExcel() async {
    try {
      final fileName = 'fees_${widget.className}.xlsx';
      final path = '/exports/fees/${widget.classId}/excel';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Generating Excel Report...')));
      await FileService.downloadAndShare(path, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showPaymentDialog(StudentFeeModel fee, FeeInstallment inst) {
    final controller = TextEditingController(text: inst.amountPaid.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Installment ${inst.installmentNo}', 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Amount: ₹${inst.targetAmount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Amount Paid',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context);
              _updatePayment(fee.studentId, inst.installmentNo, amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminGreen),
            child: const Text('Update Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalExpected = _fees.fold(0, (sum, f) => sum + f.totalFee);
    double totalPaid = _fees.fold(0, (sum, f) => sum + f.amountPaid);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${widget.className} - Fees'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Report',
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded),
            tooltip: 'Export Excel',
            onPressed: _downloadExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchFees,
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
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
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
                    Text('Financial Overview', 
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('${_fees.length} Students', style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                            icon: Icons.account_balance_rounded)),
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
                            value: '₹${(totalExpected - totalPaid).toStringAsFixed(0)}',
                            icon: Icons.pending_rounded)),
                  ],
                ),
              ],
            ),
          ),
          if (_fees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _initFees,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Initialize Fee Records (3 Inst)'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminGreen,
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _fees.isEmpty
                        ? const Center(child: Text('No Fee Records'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _fees.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _FeeCard(
                                fee: _fees[i],
                                onAction: _showPaymentDialog,
                                onReceipt: _downloadReceipt,
                                processing: _processing),
                          ),
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
  const _StatItem({required this.label, required this.value, required this.icon});

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

class _FeeCard extends StatelessWidget {
  final StudentFeeModel fee;
  final Function(StudentFeeModel, FeeInstallment) onAction;
  final Function(String, int) onReceipt;
  final bool processing;

  const _FeeCard({
    required this.fee, 
    required this.onAction, 
    required this.onReceipt,
    required this.processing
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
              child: Text(
                fee.rollNo.isNotEmpty ? fee.rollNo : '?',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(fee.studentName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Balance: ₹${fee.balance.toStringAsFixed(0)}', 
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: fee.balance > 0 ? AppTheme.unpaidRed : AppTheme.paidGreen)),
                Text('Total: ₹${fee.totalFee.toStringAsFixed(0)}', 
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ]),
          const Divider(height: 24),
          Row(
            children: List.generate(3, (idx) {
              final inst = fee.installments.firstWhere((i) => i.installmentNo == idx + 1,
                  orElse: () => FeeInstallment(installmentNo: idx + 1, status: 'unpaid'));
              
              Color statusColor;
              if (inst.isPaid) statusColor = AppTheme.paidGreen;
              else if (inst.isPartial) statusColor = Colors.orange;
              else statusColor = AppTheme.unpaidRed;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx < 2 ? 8.0 : 0),
                  child: InkWell(
                    onTap: processing ? null : () => onAction(fee, inst),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Inst ${idx + 1}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                              if (inst.isPaid) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => onReceipt(fee.studentId, inst.installmentNo),
                                  child: Icon(Icons.download_for_offline_rounded, size: 14, color: AppTheme.paidGreen),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('₹${inst.amountPaid.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                          Text('of ${inst.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
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
