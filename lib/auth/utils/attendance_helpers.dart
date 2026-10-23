class AttendanceHelpers {
  static Map<String, String> mapStatus(String s) {
    final status = s.toLowerCase();
    var finalStatus = "Present";
    var dayType = "Full Day";

    if (status.contains("late")) {
      finalStatus = "Present (Late In)";
    } else if (status.contains("short in")) {
      finalStatus = "Present (Short In)";
    } else if (status.contains("short leave")) {
      finalStatus = "Short Leave";
      dayType = "Half-Day";
    } else if (status.contains("half")) {
      finalStatus = "Half Day";
      dayType = "Half-Day";
    } else if (status.contains("leave")) {
      finalStatus = "Absent";
      dayType = "-";
    } else if (status.contains("pending")) {
      finalStatus = "Pending";
      dayType = "-";
    }

    return {"status": finalStatus, "dayType": dayType};
  }

  static List<Map<String, dynamic>> buildPunches(Map raw) {
    final punches = <Map<String, dynamic>>[];

    if (raw['check_in_time'] != null) {
      punches.add({
        "type": raw['check_in_type'] ?? "Check-In",
        "time": raw['check_in_time'],
        "address": raw['check_in_address'] ?? "N/A",
      });
    }

    if (raw['check_out_time'] != null) {
      punches.add({
        "type": raw['check_out_type'] ?? "Check-Out",
        "time": raw['check_out_time'],
        "address": raw['check_out_address'] ?? "N/A",
      });
    }

    return punches;
  }
}
