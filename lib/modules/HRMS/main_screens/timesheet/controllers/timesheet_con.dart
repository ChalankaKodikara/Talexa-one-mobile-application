import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';

// ------------------ Models ----------------------

class EmployeeTimetable {
  final int employeeTimetableID;
  final String employeeNo;
  final int? monday;
  final int? tuesday;
  final int? wednesday;
  final int? thursday;
  final int? friday;
  final int? saturday;
  final int? sunday;
  final String? employeeNameInitial;
  final DateTime? assignedDate;

  EmployeeTimetable({
    required this.employeeTimetableID,
    required this.employeeNo,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
    this.employeeNameInitial,
    this.assignedDate,
  });

  factory EmployeeTimetable.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    int? parseInt(v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));

    return EmployeeTimetable(
      employeeTimetableID: parseInt(m['EmployeeTimetableID']) ?? 0,
      employeeNo: m['employee_no'] ?? '',
      monday: parseInt(m['TimetableIDMonday']),
      tuesday: parseInt(m['TimetableIDTuesday']),
      wednesday: parseInt(m['TimetableIDWednesday']),
      thursday: parseInt(m['TimetableIDThursday']),
      friday: parseInt(m['TimetableIDFriday']),
      saturday: parseInt(m['TimetableIDSaturday']),
      sunday: parseInt(m['TimetableIDSunday']),
      employeeNameInitial: m['employee_name_initial'],
      assignedDate: parseDate(m['AssignedDate']),
    );
  }
}

class TimetableDetail {
  final int timetableID;
  final String timetableName;
  final String startCheckInTime;
  final String endCheckInTime;
  final String? graceStart;
  final String? graceEnd;
  final String? shortStart;
  final String? shortEnd;
  final String? halfStart;
  final String? halfEnd;
  final String? eveHalfStart;
  final String? eveHalfEnd;
  final String? eveShortStart;
  final String? eveShortEnd;
  final String? checkOutStart;
  final String? checkOutEnd;
  final String? type;
  final String? workingDays;

  TimetableDetail({
    required this.timetableID,
    required this.timetableName,
    required this.startCheckInTime,
    required this.endCheckInTime,
    this.graceStart,
    this.graceEnd,
    this.shortStart,
    this.shortEnd,
    this.halfStart,
    this.halfEnd,
    this.eveHalfStart,
    this.eveHalfEnd,
    this.eveShortStart,
    this.eveShortEnd,
    this.checkOutStart,
    this.checkOutEnd,
    this.type,
    this.workingDays,
  });

  factory TimetableDetail.fromMap(Map<String, dynamic> m) {
    String? s(v) => v?.toString();

    return TimetableDetail(
      timetableID: int.tryParse(m['TimetableID'].toString()) ?? 0,
      timetableName: s(m['TimetableName']) ?? '',
      startCheckInTime: s(m['StartCheckInTime']) ?? '',
      endCheckInTime: s(m['EndCheckInTime']) ?? '',
      graceStart: s(m['GracePeriodStart']),
      graceEnd: s(m['GracePeriodEnd']),
      shortStart: s(m['StartShortLeaveTime']),
      shortEnd: s(m['EndShortLeaveTime']),
      halfStart: s(m['StartHalfDayTime']),
      halfEnd: s(m['EndHalfDayTime']),
      eveHalfStart: s(m['EveningHalfDayStartTime']),
      eveHalfEnd: s(m['EveningHalfDayEndTime']),
      eveShortStart: s(m['EveningShortLeaveStartTime']),
      eveShortEnd: s(m['EveningShortLeaveEndTime']),
      checkOutStart: s(m['StartCheckOutTime']),
      checkOutEnd: s(m['EndCheckOutTime']),
      type: s(m['Type']),
      workingDays: s(m['WorkingDays']),
    );
  }
}

// ------------------ Controller ----------------------

class TimesheetController extends GetxController {
  final AuthService _api = AuthService(); // <-- your existing auth file

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final success = false.obs;

  final employeeNo = ''.obs;
  final employeeTimetable = Rxn<EmployeeTimetable>();
  final timetableDetails = <TimetableDetail>[].obs;

  Future<void> loadTimesheet(String empNo) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      /// ------ FETCH DATA FROM API ------
      final Map<String, dynamic> json =
          await _api.timesheet.fetchTimeSheetData(empNo);

// validate empty or invalid response
      if (json.isEmpty) {
        errorMessage.value = "No data received";
        success.value = false;
        return;
      }

      /// ------ PARSE RESPONSE ------
      success.value = json["success"] == true;

      employeeNo.value = json["employee_no"] ?? "";

      if (json["employeeTimetable"] != null) {
        employeeTimetable.value =
            EmployeeTimetable.fromMap(json["employeeTimetable"]);
      }

      timetableDetails.clear();
      if (json["timetableDetails"] is List) {
        timetableDetails.value = List<Map<String, dynamic>>.from(
          json["timetableDetails"],
        ).map((e) => TimetableDetail.fromMap(e)).toList();
      }
    } catch (e) {
      errorMessage.value = e.toString();
      success.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  TimetableDetail? get primaryDetail =>
      timetableDetails.isNotEmpty ? timetableDetails.first : null;
}
