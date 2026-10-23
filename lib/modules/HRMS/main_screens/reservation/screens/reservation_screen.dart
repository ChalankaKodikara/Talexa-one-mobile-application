import 'package:corehris/modules/HRMS/main_screens/reservation/controllers/reservation_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class ReservationPage extends GetView<ReservationController> {
  const ReservationPage({super.key});

  Color get primary => const Color(0xFF2D62F1);

  TextStyle get labelStyle =>
      TextStyle(fontSize: 13, color: Colors.black54, height: 1.2);
  TextStyle get valueStyle =>
      TextStyle(fontSize: 14.5, color: primary, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: Get.back,
        ),
        title: Text("Reservation",
            style: titleStyle.copyWith(color: Colors.black87)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1) Scrollable content takes remaining height
            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Tabs(
                        current: controller.tab.value,
                        onChanged: controller.setTab,
                      ),
                      const SizedBox(height: 16),

                      // Name / Emp ID
                      Row(children: [
                        Text("Name :  ", style: labelStyle),
                        Expanded(
                          child: Text(
                            controller.name.value,
                            style: valueStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text("Emp ID :  ", style: labelStyle),
                        Expanded(
                          child: Text(
                            controller.empId.value,
                            style: valueStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      _CalendarCard(
                        selectedDay: controller.selectedDay.value,
                        focusedDay: controller.focusedDay.value,
                        onDaySelected: controller.onDaySelected,
                      ),
                      const SizedBox(height: 16),

                      Text("Select Time", style: labelStyle),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => controller.pickTime(context),
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: controller.selectedTime.value == null
                                  ? "Time"
                                  : controller.selectedTime.value!
                                      .format(context),
                              hintStyle: TextStyle(
                                color: controller.selectedTime.value == null
                                    ? Colors.black38
                                    : Colors.black87,
                              ),
                              suffixIcon: const Icon(Icons.access_time_rounded),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: primary, width: 1.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text("Prepose", style: labelStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.purposeCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Type here...",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 1.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2) Bottom spacing + reactive Reserve button pinned at bottom
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        controller.canReserve ? controller.reserve : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: controller.canReserve
                          ? primary
                          : const Color(0xFFBFC1CA),
                      disabledBackgroundColor: const Color(0xFFBFC1CA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Reserve",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Local Widgets --------------------------- */

class _Tabs extends StatelessWidget {
  final ReservationTab current;
  final ValueChanged<ReservationTab> onChanged;
  const _Tabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF2D62F1);
    const pillGrey = Color(0xFFEFF1F5);

    Widget pill(String text, bool selected, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? active : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? active : pillGrey),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pillGrey,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          pill("Meeting Room", current == ReservationTab.meetingRoom,
              () => onChanged(ReservationTab.meetingRoom)),
          const SizedBox(width: 6),
          pill("Vehicles", current == ReservationTab.vehicles,
              () => onChanged(ReservationTab.vehicles)),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime? selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime, DateTime) onDaySelected;

  const _CalendarCard({
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE14E4E);
    const todayAmber = Color(0xFFFFE0B2);
    const dimGrey = Color(0xFFE3E5EA);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
        child: TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: focusedDay,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: const Icon(Icons.chevron_left_rounded),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded),
            titleTextStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, color: Colors.black54),
            weekendStyle: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration:
                const BoxDecoration(color: red, shape: BoxShape.circle),
            todayDecoration:
                const BoxDecoration(color: todayAmber, shape: BoxShape.circle),
            todayTextStyle: TextStyle(color: Colors.black87),
            selectedTextStyle: TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: Colors.black26),
            defaultTextStyle: TextStyle(color: Colors.black87),
            weekendTextStyle: TextStyle(color: Colors.black87),
            disabledTextStyle: TextStyle(color: Colors.black26),
            isTodayHighlighted: true,
          ),
          selectedDayPredicate: (d) =>
              selectedDay != null &&
              d.year == selectedDay!.year &&
              d.month == selectedDay!.month &&
              d.day == selectedDay!.day,
          onDaySelected: onDaySelected,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, foc) => _circleDay(
              ctx,
              day,
              isSelected: false,
              isToday: _isSameDay(day, DateTime.now()),
              todayFill: todayAmber,
            ),
            todayBuilder: (ctx, day, foc) => _circleDay(ctx, day,
                isSelected: false, isToday: true, todayFill: todayAmber),
            selectedBuilder: (ctx, day, foc) =>
                _circleDay(ctx, day, isSelected: true, selectedFill: red),
            outsideBuilder: (ctx, day, foc) =>
                _circleDay(ctx, day, dim: true, greyFill: dimGrey),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _circleDay(
    BuildContext ctx,
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
    bool dim = false,
    Color? selectedFill,
    Color? todayFill,
    Color? greyFill,
  }) {
    final size = 42.0;
    final text = Text(
      "${day.day}",
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : dim
                ? Colors.black26
                : Colors.black87,
      ),
    );

    Color? bg;
    if (isSelected) bg = selectedFill;
    if (!isSelected && isToday) bg = todayFill;

    return Center(
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: text,
      ),
    );
  }
}
