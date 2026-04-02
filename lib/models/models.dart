// Models for all entities used in the School Management System

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final String role;
  final String? classId;

  TokenResponse(
      {required this.accessToken,
      required this.tokenType,
      required this.role,
      this.classId});

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'],
        tokenType: json['token_type'] ?? 'bearer',
        role: json['role'],
        classId: json['class_id'],
      );
}

class ClassModel {
  final String classId;
  final String name;
  final String staffEmail;
  final int studentCount;

  ClassModel(
      {required this.classId,
      required this.name,
      required this.staffEmail,
      this.studentCount = 0});

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        classId: json['class_id'],
        name: json['name'],
        staffEmail: json['staff_email'],
        studentCount: json['student_count'] ?? 0,
      );
}

class StudentModel {
  final String studentId;
  final String name;
  final String rollNo;
  final String parentName;
  final String contact;
  final bool vanEnrolled;
  final String classId;
  final double studentFee;
  final double vanFee;
  final bool isActive;

  StudentModel({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.parentName,
    required this.contact,
    required this.vanEnrolled,
    required this.classId,
    this.studentFee = 0.0,
    this.vanFee = 0.0,
    required this.isActive,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        studentId: json['student_id'],
        name: json['name'],
        rollNo: json['roll_no'] ?? '',
        parentName: json['parent_name'],
        contact: json['contact'],
        vanEnrolled: json['van_enrolled'] ?? false,
        classId: json['class_id'],
        studentFee: (json['student_fee'] as num?)?.toDouble() ?? 0.0,
        vanFee: (json['van_fee'] as num?)?.toDouble() ?? 0.0,
        isActive: json['is_active'] ?? true,
      );
}

class FeeInstallment {
  final int installmentNo;
  final String status;
  final double targetAmount;
  final double amountPaid;
  final String? paidDate;

  FeeInstallment({
    required this.installmentNo,
    required this.status,
    this.targetAmount = 0.0,
    this.amountPaid = 0.0,
    this.paidDate,
  });

  factory FeeInstallment.fromJson(Map<String, dynamic> json) => FeeInstallment(
        installmentNo: json['installment_no'],
        status: json['status'] ?? 'unpaid',
        targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
        paidDate: json['paid_date'],
      );

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partially_paid';
}

class StudentFeeModel {
  final String studentId;
  final String studentName;
  final String rollNo;
  final String classId;
  final double totalFee;
  final double amountPaid;
  final double balance;
  final List<FeeInstallment> installments;

  StudentFeeModel({
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.classId,
    required this.totalFee,
    required this.amountPaid,
    required this.balance,
    required this.installments,
  });

  factory StudentFeeModel.fromJson(Map<String, dynamic> json) =>
      StudentFeeModel(
        studentId: json['student_id'],
        studentName: json['student_name'],
        rollNo: json['roll_no'] ?? '',
        classId: json['class_id'],
        totalFee: (json['total_fee'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        installments: (json['installments'] as List)
            .map((e) => FeeInstallment.fromJson(e))
            .toList(),
      );

  int get paidCount => installments.where((i) => i.isPaid).length;
}

class ClassFeeSummary {
  final double totalExpected;
  final double totalPaid;
  final double balance;

  ClassFeeSummary({
    required this.totalExpected,
    required this.totalPaid,
    required this.balance,
  });

  factory ClassFeeSummary.fromJson(Map<String, dynamic> json) => ClassFeeSummary(
        totalExpected: (json['total_expected'] as num?)?.toDouble() ?? 0.0,
        totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      );
}

class ClassFeesResponse {
  final List<StudentFeeModel> students;
  final ClassFeeSummary summary;

  ClassFeesResponse({
    required this.students,
    required this.summary,
  });

  factory ClassFeesResponse.fromJson(Map<String, dynamic> json) =>
      ClassFeesResponse(
        students: (json['students'] as List)
            .map((e) => StudentFeeModel.fromJson(e))
            .toList(),
        summary: ClassFeeSummary.fromJson(json['summary']),
      );
}

class VanFeeRecord {
  final int month;
  final int year;
  final String status;
  final double amount;
  final String? paidDate;

  VanFeeRecord(
      {required this.month,
      required this.year,
      required this.status,
      required this.amount,
      this.paidDate});

  factory VanFeeRecord.fromJson(Map<String, dynamic> json) => VanFeeRecord(
        month: json['month'],
        year: json['year'],
        status: json['status'] ?? 'unpaid',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        paidDate: json['paid_date'],
      );

  bool get isPaid => status == 'paid';
}

class StudentVanFeeModel {
  final String studentId;
  final String studentName;
  final String rollNo;
  final String classId;
  final List<VanFeeRecord> vanRecords;

  StudentVanFeeModel({
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.classId,
    required this.vanRecords,
  });

  factory StudentVanFeeModel.fromJson(Map<String, dynamic> json) =>
      StudentVanFeeModel(
        studentId: json['student_id'],
        studentName: json['student_name'],
        rollNo: json['roll_no'] ?? '',
        classId: json['class_id'],
        vanRecords: (json['van_records'] as List)
            .map((e) => VanFeeRecord.fromJson(e))
            .toList(),
      );
}

class StaffModel {
  final String staffId;
  final String name;
  final String designation;
  final double salary;
  final String joinDate;
  final String? contact;
  final String? email;

  StaffModel({
    required this.staffId,
    required this.name,
    required this.designation,
    required this.salary,
    required this.joinDate,
    this.contact,
    this.email,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        staffId: json['staff_id'],
        name: json['name'],
        designation: json['designation'],
        salary: (json['salary'] as num).toDouble(),
        joinDate: json['join_date'],
        contact: json['contact'],
        email: json['email'],
      );
}

class SalaryRecord {
  final int month;
  final int year;
  final String status;
  final String? paidDate;

  SalaryRecord(
      {required this.month,
      required this.year,
      required this.status,
      this.paidDate});

  factory SalaryRecord.fromJson(Map<String, dynamic> json) => SalaryRecord(
        month: json['month'],
        year: json['year'],
        status: json['status'] ?? 'not_paid',
        paidDate: json['paid_date'],
      );

  bool get isPaid => status == 'paid';
}

class StaffSalaryModel {
  final String staffId;
  final String staffName;
  final String designation;
  final double monthlySalary;
  final List<SalaryRecord> records;

  StaffSalaryModel({
    required this.staffId,
    required this.staffName,
    required this.designation,
    required this.monthlySalary,
    required this.records,
  });

  factory StaffSalaryModel.fromJson(Map<String, dynamic> json) =>
      StaffSalaryModel(
        staffId: json['staff_id'],
        staffName: json['staff_name'],
        designation: json['designation'],
        monthlySalary: (json['monthly_salary'] as num).toDouble(),
        records: (json['records'] as List)
            .map((e) => SalaryRecord.fromJson(e))
            .toList(),
      );

  int get paidCount => records.where((r) => r.isPaid).length;
}

class AttendanceRecord {
  final String studentId;
  final String? studentName;
  final String? rollNo;
  final String? contact;
  String status; // 'present' | 'absent'

  AttendanceRecord(
      {required this.studentId, this.studentName, this.rollNo, this.contact, required this.status});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        studentId: json['student_id'],
        studentName: json['student_name'],
        rollNo: json['roll_no'],
        contact: json['contact'],
        status: json['status']?.toString().toLowerCase() ?? 'absent',
      );

  Map<String, dynamic> toJson() => {'student_id': studentId, 'status': status};
}

class AttendanceHistory {
  final String classId;
  final String date;
  final int totalPresent;
  final int totalAbsent;
  final String? markedBy;
  final List<AttendanceRecord> records;

  AttendanceHistory({
    required this.classId,
    required this.date,
    required this.totalPresent,
    required this.totalAbsent,
    this.markedBy,
    required this.records,
  });

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) =>
      AttendanceHistory(
        classId: json['class_id'],
        date: json['date'],
        totalPresent: json['total_present'],
        totalAbsent: json['total_absent'],
        markedBy: json['marked_by'],
        records: (json['records'] as List)
            .map((e) => AttendanceRecord.fromJson(e))
            .toList(),
      );
}

class AttendanceSummary {
  final String date;
  final int totalPresent;
  final int totalAbsent;

  AttendanceSummary(
      {required this.date,
      required this.totalPresent,
      required this.totalAbsent});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        date: json['date'],
        totalPresent: json['total_present'],
        totalAbsent: json['total_absent'],
      );
}

class AbsenteeWhatsAppInfo {
  final String studentName;
  final String parentName;
  final String contact;
  final String? message;
  final String? whatsappUrl;

  AbsenteeWhatsAppInfo({
    required this.studentName,
    required this.parentName,
    required this.contact,
    this.message,
    this.whatsappUrl,
  });

  factory AbsenteeWhatsAppInfo.fromJson(Map<String, dynamic> json) =>
      AbsenteeWhatsAppInfo(
        studentName: json['student_name'],
        parentName: json['parent_name'],
        contact: json['contact'],
        message: json['message'],
        whatsappUrl: json['whatsapp_url'],
      );
}

class WhatsAppDataResponse {
  final String classId;
  final String date;
  final String messageTemplate;
  final List<AbsenteeWhatsAppInfo> absentees;

  WhatsAppDataResponse({
    required this.classId,
    required this.date,
    required this.messageTemplate,
    required this.absentees,
  });

  factory WhatsAppDataResponse.fromJson(Map<String, dynamic> json) =>
      WhatsAppDataResponse(
        classId: json['class_id'],
        date: json['date'],
        messageTemplate: json['message_template'],
        absentees: (json['absentees'] as List)
            .map((e) => AbsenteeWhatsAppInfo.fromJson(e))
            .toList(),
      );
}
