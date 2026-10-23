import 'package:corehris/modules/HRMS/main_screens/overtime/controllers/overtime_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OvertimeInfoScreen extends StatefulWidget {
  final int overtimeAssignmentId;

  const OvertimeInfoScreen({
    super.key,
    required this.overtimeAssignmentId,
  });

  @override
  State<OvertimeInfoScreen> createState() => _OvertimeInfoScreenState();
}

class _OvertimeInfoScreenState extends State<OvertimeInfoScreen> {
  late final OvertimeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OvertimeController>();

    // ✅ Load only once (NOT inside build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadOvertimeAssignmentDetails(widget.overtimeAssignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Overtime Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onBackground,
      ),
      body: Obx(() {
        if (controller.isDetailsLoading.value) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        final data = controller.overtimeAssignmentDetails.value;

        if (data == null) {
          return Center(
            child: Text(
              'No overtime details found',
              style: TextStyle(color: cs.onBackground.withOpacity(0.7)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoCard(
                context: context,
                title: "Employee Information",
                children: [
                  _infoRow(
                      context, Icons.person, "Employee", data['employee_name']),
                  _infoRow(context, Icons.work_outline, "Work",
                      data['name_of_work']),
                ],
              ),
              const SizedBox(height: 12),
              _infoCard(
                context: context,
                title: "Overtime Schedule",
                children: [
                  _infoRow(
                      context, Icons.calendar_today, "Date", data['ot_date']),
                  _infoRow(
                    context,
                    Icons.access_time,
                    "Planned Time",
                    "${data['planned_start_time']} - ${data['planned_end_time']}",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoCard(
                context: context,
                title: "Authorization",
                children: [
                  _infoRow(context, Icons.note_alt_outlined, "Reason",
                      data['reason']),
                  _infoRow(
                    context,
                    Icons.verified_user_outlined,
                    "Authorized By",
                    data['assigned_by_name'],
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  // 🔹 Card Wrapper (dark-mode ready)
  Widget _infoCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final shadowColor = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // 🔹 Icon + Label + Value Row (dark-mode ready)
  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary.withOpacity(0.85)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: cs.onBackground.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (value == null || value.toString().trim().isEmpty)
                      ? "-"
                      : value.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
