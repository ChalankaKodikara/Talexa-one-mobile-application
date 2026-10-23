//leave report model for the supervisor
class LeaveData {
  final bool success;
  final List<LeaveRequest> data;

  LeaveData({required this.success, required this.data});

  factory LeaveData.fromJson(Map<String, dynamic> json) {
    return LeaveData(
      success: json['success'],
      data: (json['data'] as List)
          .map((leaveRequestJson) => LeaveRequest.fromJson(leaveRequestJson))
          .toList(),
    );
  }
}

class LeaveRequest {
  final int id;
  final String employeeNo;
  final String employeeFullName;
  final String requestedDate;
  final String approvedStatus;
  final String? leaveFilePath;
  final String? leaveFileName;
  final String reason;
  final String requestingDate;
  final String remarks;
  final String dayPart;
  final String leaveCategory;
  final int supervisorId;

  LeaveRequest({
    required this.id,
    required this.employeeNo,
    required this.employeeFullName,
    required this.requestedDate,
    required this.approvedStatus,
    this.leaveFilePath,
    this.leaveFileName,
    required this.reason,
    required this.requestingDate,
    required this.remarks,
    required this.dayPart,
    required this.leaveCategory,
    required this.supervisorId,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeNo: json['employee_no'],
      employeeFullName: json['employee_fullname'],
      requestedDate: json['requested_date'],
      approvedStatus: json['approved_status_1'],
      leaveFilePath: json['leave_file_path'],
      leaveFileName: json['leave_file_name'],
      reason: json['reason'],
      requestingDate: json['requesting_date'],
      remarks: json['remarks'],
      dayPart: json['day_part'],
      leaveCategory: json['leave_category'],
      supervisorId: json['supervisor_id'],
    );
  }
}
