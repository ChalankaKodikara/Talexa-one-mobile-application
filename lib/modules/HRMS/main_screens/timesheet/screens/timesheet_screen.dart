// lib/modules/screens/main_screens/timesheet/screens/timesheet_screen.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/main_screens/timesheet/controllers/timesheet_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TimesheetScreen extends StatefulWidget {
  final String employeeNo;

  const TimesheetScreen({super.key, required this.employeeNo});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final TimesheetController controller = Get.put(TimesheetController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTimesheet(widget.employeeNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = cs.surface; // light:white | dark:darkCard
    final onCard = cs.onSurface;
    final subText = cs.onSurface.withOpacity(0.65);
    final border = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Timesheet Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: card,
        foregroundColor: onCard,
        elevation: 0,
        centerTitle: true,
      ),

      /// RefreshIndicator must wrap a scrollable widget
      body: RefreshIndicator(
        color: AppColors.primary2,
        onRefresh: () async => controller.loadTimesheet(widget.employeeNo),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!controller.success.value) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                Center(
                  child: Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : "No Timesheet Found",
                    style: TextStyle(fontSize: 16, color: subText),
                  ),
                ),
              ],
            );
          }

          final timetable = controller.employeeTimetable.value;
          final detail = controller.primaryDetail;

          if (timetable == null || detail == null) {
            return Center(
              child:
                  Text("No data available", style: TextStyle(color: subText)),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Employee info card
                _employeeCard(
                  context,
                  cardColor: card,
                  borderColor: border,
                  name: timetable.employeeNameInitial,
                  empNo: timetable.employeeNo,
                ),

                const SizedBox(height: 18),

                // ----------------------------
                // 🔆 DAY SESSION
                // ----------------------------
                Text(
                  "Day Session",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 10),

                _grid([
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Check-In",
                    value:
                        _format(detail.startCheckInTime, detail.endCheckInTime),
                    icon: LucideIcons.logIn,
                    accent: AppColors.primary2,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Grace",
                    value: _format(detail.graceStart, detail.graceEnd),
                    icon: LucideIcons.clock4,
                    accent: AppColors.warning,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Short Leave",
                    value: _format(detail.shortStart, detail.shortEnd),
                    icon: LucideIcons.userMinus,
                    accent: AppColors.info,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Half Day",
                    value: _format(detail.halfStart, detail.halfEnd),
                    icon: LucideIcons.sunMedium,
                    accent: Colors.indigo,
                  ),
                ]),

                const SizedBox(height: 22),

                // ----------------------------
                // 🌙 EVENING SESSION
                // ----------------------------
                Text(
                  "Evening Session",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 10),

                _grid([
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Evening Half",
                    value: _format(detail.eveHalfStart, detail.eveHalfEnd),
                    icon: LucideIcons.sunset,
                    accent: Colors.deepPurple,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Evening SL",
                    value: _format(detail.eveShortStart, detail.eveShortEnd),
                    icon: LucideIcons.userX,
                    accent: AppColors.danger,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Checkout",
                    value: _format(detail.checkOutStart, detail.checkOutEnd),
                    icon: LucideIcons.logOut,
                    accent: Colors.brown,
                  ),
                  _gridItem(
                    context,
                    cardColor: card,
                    borderColor: border,
                    title: "Working Days",
                    value: detail.workingDays ?? "-",
                    icon: LucideIcons.calendarDays,
                    accent: AppColors.success,
                  ),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------
  // GRID
  // ---------------------------------------------------------
  Widget _grid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: children,
    );
  }

  Widget _gridItem(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.25)),
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // EMPLOYEE CARD
  // ---------------------------------------------------------
  Widget _employeeCard(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    String? name,
    required String empNo,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary2.withOpacity(0.14),
            child: Icon(
              LucideIcons.user,
              color: cs.onSurface,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name == null || name.trim().isEmpty) ? "Employee" : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Employee No: $empNo",
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // TIME FORMATTER
  // ---------------------------------------------------------
  String _format(String? start, String? end) {
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty && e.isEmpty) return "-";
    return "${s.isEmpty ? '--' : s}  -  ${e.isEmpty ? '--' : e}";
  }
}
