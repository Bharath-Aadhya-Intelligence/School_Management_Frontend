import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/attendance_screen.dart';
import '../shared/students_screen.dart';
import 'attendance_history_screen.dart';

class AttendanceModuleScreen extends StatelessWidget {
  final String classId;
  final String className;

  const AttendanceModuleScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(className, style: Theme.of(context).textTheme.titleLarge),
              Text('Attendance & Students',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12)),
            ],
          ),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Mark'),
              Tab(icon: Icon(Icons.people_rounded), text: 'Students'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        body: TabBarView(
          children: [
            AttendanceScreen(classId: classId, className: className),
            StudentsScreen(classId: classId, className: className),
            AttendanceHistoryScreen(classId: classId),
          ],
        ),
      ),
    );
  }
}
