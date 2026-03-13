import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/file_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<StaffModel> _staff = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/staff/');
      if (!mounted) return;
      setState(() {
        _staff = (data as List).map((e) => StaffModel.fromJson(e)).toList();
        _staff.sort((a, b) => a.name.compareTo(b.name)); // Apply name-based sorting to Staff Management
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  List<StaffModel> get _filtered {
    if (_searchQuery.isEmpty) return _staff;
    final q = _searchQuery.toLowerCase();
    return _staff
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.designation.toLowerCase().contains(q))
        .toList();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final joinDateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Staff Member',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Designation *',
                      prefixIcon: Icon(Icons.work_outline_rounded))),
              const SizedBox(height: 12),
              TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Monthly Salary *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded))),
              const SizedBox(height: 12),
              TextField(
                controller: joinDateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Join Date *',
                    prefixIcon: Icon(Icons.date_range_rounded)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    joinDateCtrl.text = picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Contact',
                      prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        designationCtrl.text.trim().isEmpty ||
                        salaryCtrl.text.trim().isEmpty ||
                        joinDateCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please fill all mandatory fields'),
                          backgroundColor: AppTheme.unpaidRed));
                      return;
                    }

                    final email = emailCtrl.text.trim();
                    if (email.isNotEmpty && !_isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please enter a valid email address'),
                          backgroundColor: AppTheme.unpaidRed));
                      return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await ApiClient.post('/staff/', {
                        'name': nameCtrl.text.trim(),
                        'designation': designationCtrl.text.trim(),
                        'salary': double.tryParse(salaryCtrl.text) ?? 0,
                        'join_date': joinDateCtrl.text,
                        'contact': contactCtrl.text.trim().isEmpty
                            ? null
                            : contactCtrl.text.trim(),
                        'email': email.isEmpty ? null : email,
                      });
                      _fetchStaff();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Staff added'),
                                backgroundColor: AppTheme.paidGreen));
                      }
                    } on ApiException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppTheme.unpaidRed));
                      }
                    }
                  },
                  child: const Text('Add Staff'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(StaffModel staff) {
    final nameCtrl = TextEditingController(text: staff.name);
    final designationCtrl = TextEditingController(text: staff.designation);
    final salaryCtrl = TextEditingController(text: staff.salary.toString());
    final contactCtrl = TextEditingController(text: staff.contact ?? '');
    final emailCtrl = TextEditingController(text: staff.email ?? '');
    final joinDateCtrl = TextEditingController(text: staff.joinDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Staff Member',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Designation *',
                      prefixIcon: Icon(Icons.work_outline_rounded))),
              const SizedBox(height: 12),
              TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Monthly Salary *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded))),
              const SizedBox(height: 12),
              TextField(
                controller: joinDateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Join Date *',
                    prefixIcon: Icon(Icons.date_range_rounded)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(staff.joinDate) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    joinDateCtrl.text = picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Contact',
                      prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        designationCtrl.text.trim().isEmpty ||
                        salaryCtrl.text.trim().isEmpty ||
                        joinDateCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please fill all mandatory fields'),
                          backgroundColor: AppTheme.unpaidRed));
                      return;
                    }

                    final email = emailCtrl.text.trim();
                    if (email.isNotEmpty && !_isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please enter a valid email address'),
                          backgroundColor: AppTheme.unpaidRed));
                      return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await ApiClient.put('/staff/${staff.staffId}', {
                        'name': nameCtrl.text.trim(),
                        'designation': designationCtrl.text.trim(),
                        'salary': double.tryParse(salaryCtrl.text) ?? 0,
                        'join_date': joinDateCtrl.text,
                        'contact': contactCtrl.text.trim().isEmpty
                            ? null
                            : contactCtrl.text.trim(),
                        'email': email.isEmpty ? null : email,
                      });
                      _fetchStaff();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Staff updated'),
                                backgroundColor: AppTheme.paidGreen));
                      }
                    } on ApiException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppTheme.unpaidRed));
                      }
                    }
                  },
                  child: const Text('Update'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Remove ${staff.name} from staff records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.unpaidRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient.delete('/staff/${staff.staffId}');
        _fetchStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Staff removed'),
              backgroundColor: AppTheme.paidGreen));
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.message), backgroundColor: AppTheme.unpaidRed));
        }
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      const fileName = 'staff_list.pdf';
      const path = '/exports/staff/pdf';
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
      const fileName = 'staff_list.xlsx';
      const path = '/exports/staff/excel';
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
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _exportPdf),
          IconButton(
              icon: const Icon(Icons.table_chart_rounded),
              tooltip: 'Export Excel',
              onPressed: _exportExcel),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_add_staff_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Staff'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: AppTheme.unpaidRed),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _fetchStaff, child: const Text('Retry')),
                ]))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search staff by name or designation...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No Staff Members Found'),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) => _StaffCard(
                                  staff: filtered[i],
                                  onEdit: () => _showEditDialog(filtered[i]),
                                  onDelete: () => _deleteStaff(filtered[i])),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard(
      {required this.staff, required this.onEdit, required this.onDelete});

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.adminGreen, Color(0xFF047857)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                staff.name[0].toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(staff.name,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              Text(staff.designation,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.currency_rupee_rounded,
                    size: 13, color: AppTheme.paidGreen),
                Text(
                  '${staff.salary.toStringAsFixed(0)}/month',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.paidGreen),
                ),
                if (staff.contact != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.phone_outlined,
                      size: 13, color: AppTheme.textSecondary),
                  Text(staff.contact!,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ]),
            ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                onEdit();
              } else if (v == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined,
                          color: AppTheme.primaryBlue),
                      title: Text('Edit'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading:
                          Icon(Icons.delete_outline, color: AppTheme.unpaidRed),
                      title: Text('Delete',
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
