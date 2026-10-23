// lib/model/employee.dart
class Employee {
  final String employeeNo;
  final String employeeFullName;
  final String? employeeNameInitial;
  final String employeeCallingName;
  final String employeeDob;
  final String employeeGender;
  final String? employeeNic;
  final String? employeeMaritalStatus;
  final String employeeContactNo;
  final String? employeeLandNo;
  final String? employeePermanentAddress;
  final String? employeeTemporaryAddress;
  final String employeeEmail;
  final String personalEmail;
  final String? nationality;
  final String? religion;
  final List<EmploymentHistory> employmentHistory;

  Employee({
    required this.employeeNo,
    required this.employeeFullName,
    this.employeeNameInitial,
    required this.employeeCallingName,
    required this.employeeDob,
    required this.employeeGender,
    this.employeeNic,
    this.employeeMaritalStatus,
    required this.employeeContactNo,
    this.employeeLandNo,
    this.employeePermanentAddress,
    this.employeeTemporaryAddress,
    required this.employeeEmail,
    required this.personalEmail,
    this.nationality,
    this.religion,
    this.employmentHistory = const [],
  });

  /// Deserialize
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeNo: json['employee_no'] ?? "",
      employeeFullName: json['employee_fullname'] ?? "",
      employeeNameInitial: json['employee_name_initial'],
      employeeCallingName: json['employee_calling_name'] ?? "",
      employeeDob: json['employee_dob'] ?? "",
      employeeGender: json['employee_gender'] ?? "",
      employeeNic: json['employee_nic'],
      employeeMaritalStatus: json['employee_marital_status'],
      employeeContactNo: json['employee_contact_no'] ?? "",
      employeeLandNo: json['employee_land_no'],
      employeePermanentAddress: json['employee_permanent_address'],
      employeeTemporaryAddress: json['employee_temporary_address'],
      employeeEmail: json['employee_email'] ?? "",
      personalEmail: json['personal_email'] ?? "",
      nationality: json['nationality'],
      religion: json['religion'],
      employmentHistory: (json['employment_history'] as List<dynamic>?)
              ?.map((e) => EmploymentHistory.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Serialize
  Map<String, dynamic> toJson() {
    return {
      "employee_no": employeeNo,
      "employee_fullname": employeeFullName,
      "employee_name_initial": employeeNameInitial,
      "employee_calling_name": employeeCallingName,
      "employee_dob": employeeDob,
      "employee_gender": employeeGender,
      "employee_nic": employeeNic,
      "employee_marital_status": employeeMaritalStatus,
      "employee_contact_no": employeeContactNo,
      "employee_land_no": employeeLandNo,
      "employee_permanent_address": employeePermanentAddress,
      "employee_temporary_address": employeeTemporaryAddress,
      "employee_email": employeeEmail,
      "personal_email": personalEmail,
      "nationality": nationality,
      "religion": religion,
      "employment_history": employmentHistory.map((e) => e.toJson()).toList(),
    };
  }
}

/// ================= Employment History =================
class EmploymentHistory {
  final int id;
  final String startDate;
  final String endDate;
  final int employmentTypeId;
  final String employmentTypeName;
  final int designationId;
  final String designationName;
  final String departmentName;

  EmploymentHistory({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.employmentTypeId,
    required this.employmentTypeName,
    required this.designationId,
    required this.designationName,
    required this.departmentName,
  });

  factory EmploymentHistory.fromJson(Map<String, dynamic> json) {
    return EmploymentHistory(
      id: json['id'] ?? 0,
      startDate: json['start_date'] ?? "",
      endDate: json['end_date'] ?? "",
      employmentTypeId: json['employment_type_id'] ?? 0,
      employmentTypeName: json['employment_type_name'] ?? "",
      designationId: json['designation_id'] ?? 0,
      designationName: json['designation_name'] ?? "",
      departmentName: json['department_name'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "start_date": startDate,
      "end_date": endDate,
      "employment_type_id": employmentTypeId,
      "employment_type_name": employmentTypeName,
      "designation_id": designationId,
      "designation_name": designationName,
      "department_name": departmentName,
    };
  }
}
