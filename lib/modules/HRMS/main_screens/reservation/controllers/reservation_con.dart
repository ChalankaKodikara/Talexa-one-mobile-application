// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/utils/app_alert.dart';

enum ReservationTab { meetingRoom, vehicles }

class ReservationController extends GetxController {
  // Replace with your auth/user store as needed
  final name = 'Thameera Dhananjaya'.obs;
  final empId = 'Emp432535'.obs;

  // Tab & calendar state
  final tab = ReservationTab.meetingRoom.obs;
  final focusedDay = DateTime.now().obs;
  final selectedDay = Rxn<DateTime>();

  // Time & purpose
  final selectedTime = Rxn<TimeOfDay>();
  final purposeCtrl = TextEditingController();

  // Derived
  bool get canReserve =>
      selectedDay.value != null && selectedTime.value != null;

  void setTab(ReservationTab t) => tab.value = t;

  void onDaySelected(DateTime day, DateTime focus) {
    selectedDay.value = DateTime(day.year, day.month, day.day);
    focusedDay.value = focus;
  }

  Future<void> pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: const TimePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) selectedTime.value = t;
  }

  void reserve() {
    if (!canReserve) return;

    final d = selectedDay.value!;
    final t = selectedTime.value!;
    final payload = {
      "type":
          tab.value == ReservationTab.meetingRoom ? "MEETING_ROOM" : "VEHICLE",
      "date":
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
      "time":
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
      "purpose": purposeCtrl.text.trim(),
      "empId": empId.value,
    };

    // TODO: replace with your Dio/HTTP call
    // await dio.post('/v1/reservations', data: payload);

    AppAlert.toast(
      title: "Reservation",
      message: "Submitted successfully",
    );
  }

  @override
  void onClose() {
    purposeCtrl.dispose();
    super.onClose();
  }
}
