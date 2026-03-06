import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/fees_screen.dart';
import '../shared/van_fees_screen.dart';

class FeesModuleScreen extends StatelessWidget {
  final String classId;
  final String className;

  const FeesModuleScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(className, style: Theme.of(context).textTheme.titleLarge),
              Text('Fees & Payments',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12)),
            ],
          ),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Student Fees'),
              Tab(icon: Icon(Icons.directions_bus_rounded), text: 'Van Fees'),
            ],
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        body: TabBarView(
          children: [
            FeesScreen(classId: classId, className: className),
            VanFeesScreen(classId: classId, className: className),
          ],
        ),
      ),
    );
  }
}
