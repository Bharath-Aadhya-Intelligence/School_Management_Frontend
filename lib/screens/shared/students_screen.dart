import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/sort_utils.dart';
import '../../widgets/app_drawer.dart';

class StudentsScreen extends StatefulWidget {
  final String classId;
  final String className;
  const StudentsScreen(
      {super.key, required this.classId, required this.className});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<StudentModel> _students = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/students/${widget.classId}');
      if (!mounted) return;
      final students = (data as List).map((e) => StudentModel.fromJson(e)).toList();
      students.sort((a, b) => SortUtils.compareNatural(a.rollNo, b.rollNo));
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  List<StudentModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _students;
    return _students
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.rollNo.toLowerCase().contains(q) ||
            s.parentName.toLowerCase().contains(q) ||
            s.contact.contains(q))
        .toList();
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final studentFeeCtrl = TextEditingController();
    final vanFeeCtrl = TextEditingController();
    bool vanEnrolled = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Student',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(
                    controller: rollCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Roll Number',
                        prefixIcon: Icon(Icons.numbers_rounded))),
                if (vanEnrolled) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: vanFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Total Van Fee (Annual)',
                          prefixIcon: Icon(Icons.directions_bus_rounded))),
                ],
                const SizedBox(height: 12),
                TextField(
                    controller: parentCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Parent Name',
                        prefixIcon: Icon(Icons.family_restroom_rounded))),
                const SizedBox(height: 12),
                TextField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 12),
                TextField(
                    controller: studentFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Student Fee (Total)',
                        prefixIcon: Icon(Icons.payments_outlined))),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: vanEnrolled,
                  onChanged: (v) => setModalState(() => vanEnrolled = v),
                  title: Text('Van Enrolled',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  secondary: const Icon(Icons.directions_bus_rounded),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty ||
                          rollCtrl.text.isEmpty ||
                          parentCtrl.text.isEmpty ||
                          contactCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await ApiClient.post('/students/', {
                          'name': nameCtrl.text.trim(),
                          'roll_no': rollCtrl.text.trim(),
                          'parent_name': parentCtrl.text.trim(),
                          'contact': contactCtrl.text.trim(),
                          'van_enrolled': vanEnrolled,
                          'class_id': widget.classId,
                          'student_fee':
                              double.tryParse(studentFeeCtrl.text.trim()) ?? 0,
                          'van_fee':
                              double.tryParse(vanFeeCtrl.text.trim()) ?? 0,
                        });
                        _fetchStudents();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Student added successfully'),
                                backgroundColor: AppTheme.paidGreen),
                          );
                        }
                      } on ApiException catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.message),
                              backgroundColor: AppTheme.unpaidRed));
                      }
                    },
                    child: const Text('Add Student'),
                  )),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(StudentModel student) {
    final nameCtrl = TextEditingController(text: student.name);
    final rollCtrl = TextEditingController(text: student.rollNo);
    final parentCtrl = TextEditingController(text: student.parentName);
    final contactCtrl = TextEditingController(text: student.contact);
    // Note: Fees are not in StudentModel yet, so we'll start with empty or fetch if needed
    final studentFeeCtrl =
        TextEditingController(text: student.studentFee.toStringAsFixed(0));
    final vanFeeCtrl =
        TextEditingController(text: student.vanFee.toStringAsFixed(0));
    bool vanEnrolled = student.vanEnrolled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Student',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(
                    controller: rollCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Roll Number',
                        prefixIcon: Icon(Icons.numbers_rounded))),
                if (vanEnrolled) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: vanFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Total Van Fee (Annual)',
                          prefixIcon: Icon(Icons.directions_bus_rounded))),
                ],
                const SizedBox(height: 12),
                TextField(
                    controller: parentCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Parent Name',
                        prefixIcon: Icon(Icons.family_restroom_rounded))),
                const SizedBox(height: 12),
                TextField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Contact',
                        prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 12),
                TextField(
                    controller: studentFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Student Fee (Total)',
                        prefixIcon: Icon(Icons.payments_outlined))),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: vanEnrolled,
                  onChanged: (v) => setModalState(() => vanEnrolled = v),
                  title: Text('Van Enrolled',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  secondary: const Icon(Icons.directions_bus_rounded),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiClient.put('/students/${student.studentId}', {
                          'name': nameCtrl.text.trim(),
                          'roll_no': rollCtrl.text.trim(),
                          'parent_name': parentCtrl.text.trim(),
                          'contact': contactCtrl.text.trim(),
                          'van_enrolled': vanEnrolled,
                          'student_fee':
                              double.tryParse(studentFeeCtrl.text.trim()) ?? 0,
                          'van_fee':
                              double.tryParse(vanFeeCtrl.text.trim()) ?? 0,
                        });
                        if (!mounted) return;
                        _fetchStudents();
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Student updated'),
                                  backgroundColor: AppTheme.paidGreen));
                      } on ApiException catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.message),
                              backgroundColor: AppTheme.unpaidRed));
                      }
                    },
                    child: const Text('Save'),
                  )),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove ${student.name} from this class?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppTheme.unpaidRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient.delete('/students/${student.studentId}');
        if (!mounted) return;
        _fetchStudents();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Student removed'),
              backgroundColor: AppTheme.paidGreen));
      } on ApiException catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_student_fab',
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, roll no, parent...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text(
                '${filtered.length} student${filtered.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
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
                            onPressed: _fetchStudents,
                            child: const Text('Retry')),
                      ]))
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: _searchQuery.isEmpty
                                ? 'No Students'
                                : 'No Results',
                            subtitle: _searchQuery.isEmpty
                                ? 'Add students using the button below'
                                : 'Try a different search term',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final s = filtered[i];
                              return _StudentCard(
                                student: s,
                                onEdit: () => _showEditDialog(s),
                                onDelete: () => _deleteStudent(s),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard(
      {required this.student, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                student.rollNo.isNotEmpty ? student.rollNo : '?',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(student.name,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (!student.isActive) ...[
                    const SizedBox(width: 6),
                    StatusBadge(
                        status: 'inactive',
                        paidLabel: 'Active',
                        unpaidLabel: 'Inactive'),
                  ],
                  if (student.vanEnrolled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.staffPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.directions_bus_rounded,
                            size: 11, color: AppTheme.staffPurple),
                        const SizedBox(width: 3),
                        Text('Van',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.staffPurple)),
                      ]),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${student.parentName} • ${student.contact}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading:
                          Icon(Icons.delete_outline, color: AppTheme.unpaidRed),
                      title: Text('Remove',
                          style: TextStyle(color: AppTheme.unpaidRed)),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    );
  }
}
