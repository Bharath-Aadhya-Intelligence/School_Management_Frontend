import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  const AttendanceScreen(
      {super.key, required this.classId, required this.className});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceSummary> _summaries = [];
  List<StudentModel> _students = [];
  AttendanceHistory? _todayAttendance;
  bool _loadingStudents = true;
  bool _loadingSummary = true;
  bool _submitting = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceMap = {}; // studentId -> status

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchStudents(), _fetchSummary()]);
    await _fetchTodayAttendance();
  }

  Future<void> _fetchStudents() async {
    try {
      final data = await ApiClient.get('/students/${widget.classId}');
      final students = (data as List)
          .map((e) => StudentModel.fromJson(e))
          .where((s) => s.isActive)
          .toList();
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

  Future<void> _fetchSummary() async {
    try {
      final data = await ApiClient.get('/attendance/${widget.classId}');
      setState(() {
        _summaries =
            (data as List).map((e) => AttendanceSummary.fromJson(e)).toList();
        _loadingSummary = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingSummary = false;
      });
    }
  }

  Future<void> _fetchTodayAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final data =
          await ApiClient.get('/attendance/${widget.classId}/$dateStr');
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

  Future<void> _submitAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _submitting = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _students
        .map((s) => {
              'student_id': s.studentId,
              'status': _attendanceMap[s.studentId] ?? 'present',
            })
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

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved for $dateStr'),
            backgroundColor: AppTheme.paidGreen,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int get _presentCount =>
      _attendanceMap.values.where((v) => v == 'present').length;
  int get _absentCount =>
      _attendanceMap.values.where((v) => v == 'absent').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Attendance'),
        elevation: 0,
      ),
      body: _buildMarkAttendanceTab(),
    );
  }

  Widget _buildMarkAttendanceTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            size: 64, color: AppTheme.unpaidRed),
        const SizedBox(height: 16),
        Text(_error!),
      ]));
    }

    return Column(
      children: [
        // Date Selector + Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark]),
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
                      _attendanceMap = {
                        for (final s in _students) s.studentId: 'present'
                      };
                    });
                    await _fetchTodayAttendance();
                  }
                },
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_rounded,
                      color: Colors.white70, size: 16),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(children: [
                    Text('$_presentCount',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    Text('Present',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: Column(children: [
                    Text('$_absentCount',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    Text('Absent',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: Column(children: [
                    Text('${_students.length}',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    Text('Total',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ]),
            ],
          ),
        ),

        // Mark All Buttons
        if (_students.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    for (final s in _students)
                      _attendanceMap[s.studentId] = 'present';
                  }),
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('All Present'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.paidGreen,
                      side: const BorderSide(color: AppTheme.paidGreen)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    for (final s in _students)
                      _attendanceMap[s.studentId] = 'absent';
                  }),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('All Absent'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.unpaidRed,
                      side: const BorderSide(color: AppTheme.unpaidRed)),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 8),

        // Student List
        Expanded(
          child: _students.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline_rounded, title: 'No Students')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = _students[i];
                    final status = _attendanceMap[s.studentId] ?? 'present';
                    final isPresent = status == 'present';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isPresent
                            ? AppTheme.paidGreen.withOpacity(0.12)
                            : AppTheme.unpaidRed.withOpacity(0.12),
                        child: Text(
                          s.rollNo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPresent
                                ? AppTheme.paidGreen
                                : AppTheme.unpaidRed,
                          ),
                        ),
                      ),
                      title: Text(s.name,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(s.parentName,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _attendanceMap[s.studentId] = 'present'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? AppTheme.paidGreen
                                  : AppTheme.surfaceLight,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8)),
                              border: Border.all(
                                  color: isPresent
                                      ? AppTheme.paidGreen
                                      : AppTheme.borderLight),
                            ),
                            child: Text('P',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isPresent
                                        ? Colors.white
                                        : AppTheme.textSecondary)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                              () => _attendanceMap[s.studentId] = 'absent'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: !isPresent
                                  ? AppTheme.unpaidRed
                                  : AppTheme.surfaceLight,
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8)),
                              border: Border.all(
                                  color: !isPresent
                                      ? AppTheme.unpaidRed
                                      : AppTheme.borderLight),
                            ),
                            child: Text('A',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: !isPresent
                                        ? Colors.white
                                        : AppTheme.textSecondary)),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),

        // Submit Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ElevatedButton.icon(
              onPressed:
                  (_submitting || _students.isEmpty) ? null : _submitAttendance,
              icon: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: Text(_todayAttendance != null
                  ? 'Update Attendance'
                  : 'Submit Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.paidGreen,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
