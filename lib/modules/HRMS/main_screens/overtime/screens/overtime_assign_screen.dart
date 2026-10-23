import 'package:corehris/modules/HRMS/main_screens/overtime/controllers/overtime_con.dart';
import 'package:corehris/modules/HRMS/main_screens/overtime/screens/overtime_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OvertimeAssignScreen extends StatefulWidget {
  const OvertimeAssignScreen({super.key});

  @override
  State<OvertimeAssignScreen> createState() => _OvertimeAssignScreenState();
}

class _OvertimeAssignScreenState extends State<OvertimeAssignScreen> {
  late final OvertimeController controller;

  @override
  void initState() {
    super.initState();

    // ✅ only create once (avoid re-put on rebuilds)
    controller = Get.put(OvertimeController());

    // ✅ load once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (controller.employeeNo.value.trim().isNotEmpty) {
        await controller.loadOvertimeByEmployee(controller.employeeNo.value);
      } else {
        // if controller loads employeeNo inside onInit, this will still work after it updates
        // optional: you can call controller.initEmployeeNoAndLoad() if you have such method
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Overtime'),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onBackground,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        if (controller.overtimeList.isEmpty) {
          return Center(
            child: Text(
              'No overtime assigned',
              style: TextStyle(color: cs.onBackground.withOpacity(0.7)),
            ),
          );
        }

        return RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            final empNo = controller.employeeNo.value.trim();
            if (empNo.isNotEmpty) {
              await controller.loadOvertimeByEmployee(empNo);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.overtimeList.length,
            itemBuilder: (context, index) {
              final ot = controller.overtimeList[index];
              final isSubmitted = controller.isOvertimeSubmitted(ot);

              final shadowColor = Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.35 : 0.10,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  title: Text(
                    ot['name_of_work'] ?? 'Overtime',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onBackground,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _subLine(
                          context,
                          icon: Icons.calendar_today,
                          text: 'Date: ${ot['ot_date'] ?? '-'}',
                        ),
                        const SizedBox(height: 4),
                        _subLine(
                          context,
                          icon: Icons.access_time,
                          text:
                              'Planned: ${ot['planned_start_time'] ?? '-'} - ${ot['planned_end_time'] ?? '-'}',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isSubmitted ? Icons.verified : Icons.pending,
                              size: 16,
                              color: isSubmitted
                                  ? cs.primary
                                  : cs.tertiary.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSubmitted
                                  ? 'Status: Submitted'
                                  : 'Status: Pending',
                              style: TextStyle(
                                color: isSubmitted
                                    ? cs.primary
                                    : cs.onBackground.withOpacity(0.75),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: cs.onBackground.withOpacity(0.55),
                  ),
                  onTap: () {
                    final id = ot['overtime_assignment_id'];
                    if (id == null) return;

                    Get.to(
                      () => OvertimeInfoScreen(
                        overtimeAssignmentId: id,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _subLine(BuildContext context,
      {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onBackground.withOpacity(0.55)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: cs.onBackground.withOpacity(0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
