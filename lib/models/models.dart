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

  ClassModel(
      {required this.classId, required this.name, required this.staffEmail});

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        classId: json['class_id'],
        name: json['name'],
        staffEmail: json['staff_email'],
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
  final bool isActive;

  StudentModel({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.parentName,
    required this.contact,
    required this.vanEnrolled,
    required this.classId,
    required this.isActive,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        studentId: json['student_id'],
        name: json['name'],
        rollNo: json['roll_no'],
        parentName: json['parent_name'],
        contact: json['contact'],
        vanEnrolled: json['van_enrolled'] ?? false,
        classId: json['class_id'],
        isActive: json['is_active'] ?? true,
      );
}

class FeeInstallment {
  final int installmentNo;
  final String status;
  final String? paidDate;

  FeeInstallment(
      {required this.installmentNo, required this.status, this.paidDate});

  factory FeeInstallment.fromJson(Map<String, dynamic> json) => FeeInstallment(
        installmentNo: json['installment_no'],
        status: json['status'] ?? 'unpaid',
        paidDate: json['paid_date'],
      );

  bool get isPaid => status == 'paid';
}

class StudentFeeModel {
  final String studentId;
  final String studentName;
  final String classId;
  final List<FeeInstallment> installments;

  StudentFeeModel({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.installments,
  });

  factory StudentFeeModel.fromJson(Map<String, dynamic> json) =>
      StudentFeeModel(
        studentId: json['student_id'],
        studentName: json['student_name'],
        classId: json['class_id'],
        installments: (json['installments'] as List)
            .map((e) => FeeInstallment.fromJson(e))
            .toList(),
      );

  int get paidCount => installments.where((i) => i.isPaid).length;
}

class VanFeeRecord {
  final int month;
  final int year;
  final String status;
  final String? paidDate;

  VanFeeRecord(
      {required this.month,
      required this.year,
      required this.status,
      this.paidDate});

  factory VanFeeRecord.fromJson(Map<String, dynamic> json) => VanFeeRecord(
        month: json['month'],
        year: json['year'],
        status: json['status'] ?? 'unpaid',
        paidDate: json['paid_date'],
      );

  bool get isPaid => status == 'paid';
}

class StudentVanFeeModel {
  final String studentId;
  final String studentName;
  final String classId;
  final List<VanFeeRecord> vanRecords;

  StudentVanFeeModel({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.vanRecords,
  });

  factory StudentVanFeeModel.fromJson(Map<String, dynamic> json) =>
      StudentVanFeeModel(
        studentId: json['student_id'],
        studentName: json['student_name'],
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
  String status; // 'present' | 'absent'

  AttendanceRecord(
      {required this.studentId, this.studentName, required this.status});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        studentId: json['student_id'],
        studentName: json['student_name'],
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
