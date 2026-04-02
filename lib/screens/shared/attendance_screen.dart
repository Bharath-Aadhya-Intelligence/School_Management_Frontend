import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/sort_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/file_service.dart';
import '../../widgets/bulk_notification_sheet.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool showAppBar;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
    this.showAppBar = true,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<StudentModel> _students = [];
  AttendanceHistory? _todayAttendance;
  bool _loadingStudents = true;
  bool _submitting = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceMap = {}; // studentId -> status
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _attendanceMap.clear();
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await _fetchStudents();
    await _fetchTodayAttendance();
  }

  Future<void> _fetchStudents() async {
    try {
      final data = await ApiClient.get('/students/${widget.classId}');
      if (!mounted) return;
      final students =
          (data as List).map((e) => StudentModel.fromJson(e)).toList();
      setState(() {
        _students = students;
        _loadingStudents = false;
        // Initialize attendance map
        for (final s in students) {
          if (!_attendanceMap.containsKey(s.studentId)) {
            _attendanceMap[s.studentId] = 'present';
          }
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingStudents = false;
      });
    }
  }

  Future<void> _fetchTodayAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final data = await ApiClient.get(
        '/attendance/${widget.classId}/$dateStr',
      );
      if (!mounted) return;
      final history = AttendanceHistory.fromJson(data);
      setState(() {
        _todayAttendance = history;
        for (final r in history.records) {
          _attendanceMap[r.studentId] = r.status;
        }
      });
    } catch (_) {
      // No attendance record for this date yet — keep defaults
    }
  }

  Future<void> _showWhatsAppPrompt() async {
    if (_absentCount == 0) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final json = await ApiClient.get(
        '/attendance/${widget.classId}/$dateStr/whatsapp-data',
      );
      final data = WhatsAppDataResponse.fromJson(json);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BulkNotificationSheet(
          data: data,
          date: _selectedDate,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching WhatsApp data: $e');
    }
  }

  Future<void> _submitAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _submitting = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _students
        .map(
          (s) => {
            'student_id': s.studentId,
            'status': _attendanceMap[s.studentId] ?? 'present',
          },
        )
        .toList();

    try {
      final body = {
        'class_id': widget.classId,
        'date': dateStr,
        'records': records,
      };

      if (_todayAttendance != null) {
        await ApiClient.put('/attendance/${widget.classId}/$dateStr', body);
      } else {
        await ApiClient.post('/attendance/', body);
      }

      if (!mounted) return;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Attendance successfully submitted for $dateStr.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            action: _absentCount > 0
                ? SnackBarAction(
                    label: 'NOTIFY',
                    textColor: Colors.white,
                    onPressed: _showWhatsAppPrompt,
                  )
                : null,
            backgroundColor: AppTheme.paidGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.unpaidRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int get _presentCount {
    if (_todayAttendance != null && _attendanceMap.isEmpty) {
      return _todayAttendance!.totalPresent;
    }
    return _attendanceMap.values
        .where((v) => v.toLowerCase() == 'present' || v.toLowerCase() == 'p')
        .length;
  }

  int get _absentCount {
    if (_todayAttendance != null && _attendanceMap.isEmpty) {
      return _todayAttendance!.totalAbsent;
    }
    return _attendanceMap.values
        .where((v) => v.toLowerCase() == 'absent' || v.toLowerCase() == 'a')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text('${widget.className} - Attendance'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                await FileService.downloadAndShare(
                  '/exports/attendance/${widget.classId}/${_selectedDate.year}/${_selectedDate.month}/pdf',
                  'attendance_${widget.classId}_${_selectedDate.year}_${_selectedDate.month}.pdf',
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: AppTheme.unpaidRed),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isAscending ? Icons.sort_by_alpha_rounded : Icons.sort_rounded,
            ),
            tooltip: _isAscending ? 'Sort Ascending' : 'Sort Descending',
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                // Re-sort the existing list
                _students.sort((a, b) => _isAscending
                    ? SortUtils.compareNatural(a.rollNo, b.rollNo)
                    : SortUtils.compareNatural(b.rollNo, a.rollNo));
              });
            },
          ),
        ],
      ) : null,
      body: _buildMarkAttendanceTab(),
    );
  }

  Widget _buildMarkAttendanceTab() {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;

    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.unpaidRed,
            ),
            const SizedBox(height: 16),
            Text(_error!),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Date Selector + Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Date Picker Row
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _todayAttendance = null;
                      _attendanceMap.clear();
                      for (final s in _students) {
                        _attendanceMap[s.studentId] = 'present';
                      }
                    });
                    await _fetchTodayAttendance();
                  }
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_presentCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Present',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.white24),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_absentCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Absent',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.white24),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_students.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_todayAttendance?.markedBy != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Marked By: ${_todayAttendance!.markedBy}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Mark All Buttons - Hide for Admin
        if (_students.isNotEmpty && !isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      for (final s in _students) {
                        _attendanceMap[s.studentId] = 'present';
                      }
                    }),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('All Present'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.paidGreen,
                      side: const BorderSide(color: AppTheme.paidGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      for (final s in _students) {
                        _attendanceMap[s.studentId] = 'absent';
                      }
                    }),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('All Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.unpaidRed,
                      side: const BorderSide(color: AppTheme.unpaidRed),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Student List
        Expanded(
          child: _students.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text('No Students Found'),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, isAdmin ? 16 : 100),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = _students[i];
                    final status = (_attendanceMap[s.studentId] ?? 'present')
                        .toLowerCase();
                    final isPresent = status == 'present' || status == 'p';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isPresent
                            ? AppTheme.paidGreen.withValues(alpha: 0.12)
                            : AppTheme.unpaidRed.withValues(alpha: 0.12),
                        child: Text(
                          s.rollNo.isNotEmpty ? s.rollNo : '?',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPresent
                                ? AppTheme.paidGreen
                                : AppTheme.unpaidRed,
                          ),
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        s.parentName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: isAdmin
                                ? null
                                : () => setState(
                                      () => _attendanceMap[s.studentId] =
                                          'present',
                                    ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppTheme.paidGreen
                                    : AppTheme.lightBg,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: isPresent
                                      ? AppTheme.paidGreen
                                      : AppTheme.lightBorder,
                                ),
                              ),
                              child: Text(
                                'P',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isPresent
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isAdmin
                                ? null
                                : () => setState(
                                      () => _attendanceMap[s.studentId] =
                                          'absent',
                                    ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: !isPresent
                                    ? AppTheme.unpaidRed
                                    : AppTheme.lightBg,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: !isPresent
                                      ? AppTheme.unpaidRed
                                      : AppTheme.lightBorder,
                                ),
                              ),
                              child: Text(
                                'A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !isPresent
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Submit Button - Hide for Admin
        if (!isAdmin)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: (_submitting || _students.isEmpty)
                        ? null
                        : _submitAttendance,
                    icon: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _todayAttendance != null
                          ? 'Update Attendance'
                          : 'Submit Attendance',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.paidGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
