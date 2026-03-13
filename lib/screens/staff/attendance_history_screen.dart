import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/sort_utils.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String classId;

  const AttendanceHistoryScreen({super.key, required this.classId});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  int _totalPresent = 0;
  int _totalAbsent = 0;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    if (widget.classId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final json = await ApiClient.get('/attendance/${widget.classId}/$dateStr');

      if (!mounted) return;

      final history = AttendanceHistory.fromJson(json);

      setState(() {
        _attendanceRecords = history.records;
        _attendanceRecords.sort((a, b) => SortUtils.compareNatural(a.rollNo ?? '', b.rollNo ?? ''));
        _totalPresent = history.totalPresent;
        _totalAbsent = history.totalAbsent;
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.staffPurple,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAttendanceHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classId.isEmpty) {
      return Center(
        child: Text(
          'No class assigned to view history.',
          style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Date Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkBorder
                          : AppTheme.borderLight))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded,
                    color: AppTheme.staffPurple),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: AppTheme.unpaidRed),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchAttendanceHistory,
                                child: const Text('Retry'),
                              ),
                            ],
                          )),
                    )
                  : _attendanceRecords.isEmpty
                      ? Center(
                          child: Text(
                            'No attendance records found for this date.',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary),
                          ),
                        )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              _StatChip(
                                label: 'Present',
                                value: '$_totalPresent',
                                color: AppTheme.paidGreen,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: 'Absent',
                                value: '$_totalAbsent',
                                color: AppTheme.unpaidRed,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final record = _attendanceRecords[index];
                              final status = record.status;
                              final studentName = record.studentName ?? 'Unknown Student';
                              final rollNo = record.rollNo ?? '-';
                              final isPresent = status == 'present' || status == 'p';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.darkBorder
                                        : AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPresent
                                          ? AppTheme.paidGreen.withOpacity(0.12)
                                          : AppTheme.unpaidRed.withOpacity(0.12),
                                      child: Text(
                                        rollNo.isNotEmpty ? rollNo : '?',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isPresent
                                              ? AppTheme.paidGreen
                                              : AppTheme.unpaidRed,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        studentName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? AppTheme.paidGreen.withOpacity(0.15)
                                            : AppTheme.unpaidRed
                                                .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPresent ? 'Present' : 'Absent',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isPresent
                                              ? AppTheme.paidGreen
                                              : AppTheme.unpaidRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value ',
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
