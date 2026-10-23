// Talexa HRMS • Leave Center
// Modern, responsive light/dark layout. Existing business logic is unchanged.
import 'package:corehris/components/leave_card/leave_card.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/calendar_leaves_page.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_menu_con.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leave_encash_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leave_recall_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leave_request_detail_page.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/leave_report.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeaveMenuScreen extends StatelessWidget {
  LeaveMenuScreen({super.key});

  final LeaveMenuController controller = Get.isRegistered<LeaveMenuController>()
      ? Get.find<LeaveMenuController>()
      : Get.put(LeaveMenuController());

  static const _blue = Color(0xFF1769E8);

  bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _surface(BuildContext context) =>
      _dark(context) ? const Color(0xFF1A2231) : Colors.white;

  Color _ink(BuildContext context) =>
      _dark(context) ? const Color(0xFFF4F7FF) : const Color(0xFF152238);

  Color _muted(BuildContext context) =>
      _dark(context) ? const Color(0xFFA0ADC0) : const Color(0xFF78869B);

  BoxDecoration _panel(BuildContext context, {double radius = 22}) =>
      BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _dark(context)
              ? const Color(0xFF303C4E)
              : const Color(0xFFE9EEF5),
        ),
        boxShadow: null,
      );

  void _applyLeave() => Get.to(() => LeavesCalendarPage());

  void _viewReport() => Get.to(
        () => LeaveReportPage(username: controller.employeeId.value),
      );

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0E1522) : const Color(0xFFF6F9FE),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            dark ? const Color(0xFF0E1522) : const Color(0xFFF6F9FE),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        title: Text(
          'Leave Center',
          style: TextStyle(
            color: _ink(context),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Leave reports',
            onPressed: _viewReport,
            icon: const Icon(Icons.history_rounded, size: 23),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary2,
        onRefresh: controller.refreshAll,
        child: Obx(() {
          final leaveCount = controller.leaveList.length;
          final requestCount = controller.leaveRequests.length;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _hero(context, leaveCount, requestCount),
              const SizedBox(height: 22),
              _section(context, 'Leave Balances',
                  'Your available entitlements at a glance'),
              const SizedBox(height: 12),
              _balances(context),
              const SizedBox(height: 23),
              _section(context, 'Quick Services',
                  'Manage your leave without extra steps'),
              const SizedBox(height: 12),
              _services(context),
              const SizedBox(height: 23),
              _section(context, 'Recent Requests',
                  'Latest updates to your applications',
                  action: 'View all', onAction: _viewReport),
              const SizedBox(height: 12),
              _requests(context),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: dark ? const Color(0xFF0E1522) : const Color(0xFFF6F9FE),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _applyLeave,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
              label: const Text('Apply for Leave',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, int leaveCount, int requestCount) {
    final dark = _dark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B2835) : const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: dark ? const Color(0xFF324152) : const Color(0xFFDCECF1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2F4553) : Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.spa_outlined,
                  color: Color(0xFF159C91), size: 21)),
          const Spacer(),
          Text('MY LEAVE SPACE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _muted(context))),
        ]),
        const SizedBox(height: 15),
        Text('Take time for what matters.',
            style: TextStyle(
                color: _ink(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.65,
                height: 1.16)),
        const SizedBox(height: 6),
        Text('Your balances and leave requests, all in one place.',
            style:
                TextStyle(color: _muted(context), fontSize: 12, height: 1.5)),
        const SizedBox(height: 17),
        Row(children: [
          _statPill(
              context, Icons.category_outlined, '$leaveCount leave types'),
          const SizedBox(width: 8),
          _statPill(
              context, Icons.assignment_outlined, '$requestCount requests'),
        ]),
      ]),
    );
  }

  Widget _statPill(BuildContext context, IconData icon, String label) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
              color: _dark(context) ? const Color(0xFF293848) : Colors.white,
              borderRadius: BorderRadius.circular(100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: const Color(0xFF159C91)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: _ink(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]));

  Widget _section(BuildContext context, String title, String subtitle,
      {String? action, VoidCallback? onAction}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                color: _ink(context),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 3),
          Text(subtitle,
              style: TextStyle(color: _muted(context), fontSize: 11.5)),
        ]),
      ),
      if (action != null && onAction != null)
        TextButton(
            onPressed: onAction,
            child: Text(action,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700))),
    ]);
  }

  Widget _balances(BuildContext context) {
    if (controller.leaveList.isEmpty) {
      return _empty(
          context,
          Icons.calendar_today_outlined,
          'No leave balances available',
          'Pull down to refresh your entitlements.');
    }
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 650 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.leaveList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: columns == 2 ? 1.30 : 1.5,
        ),
        itemBuilder: (context, index) {
          final leave = controller.leaveList[index];
          final tones = [
            const Color(0xFF0DADA8),
            const Color(0xFF3974DB),
            const Color(0xFFB477D0),
            const Color(0xFFCB853A)
          ];
          final tone = tones[index % tones.length];
          final label = leave.categoryName.toString().trim();
          final available = leave.actualLeaveCounts.toString();
          final total = leave.leaveCount.toString();
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _dark(context)
                      ? const Color(0xFF303C4E)
                      : const Color(0xFFE6EBF2)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                        color: tone.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.calendar_month_outlined,
                        color: tone, size: 16)),
                const Spacer(),
                Text('AVAILABLE',
                    style: TextStyle(
                        color: _muted(context),
                        fontSize: 9,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w700)),
              ]),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(available,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: _ink(context))),
                const SizedBox(width: 4),
                Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('days',
                        style:
                            TextStyle(fontSize: 10, color: _muted(context)))),
              ]),
              const SizedBox(height: 5),
              Text(label.isEmpty ? 'Leave' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _ink(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('of $total total',
                  style: TextStyle(color: _muted(context), fontSize: 10)),
            ]),
          );
        },
      );
    });
  }

  Widget _services(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _serviceTile(
          context,
          icon: Icons.currency_exchange_rounded,
          title: 'Leave Encash',
          subtitle: 'Convert eligible days',
          tint: const Color(0xFFF5A524),
          onTap: () => Get.to(() => LeaveEncashScreen()),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: _serviceTile(
          context,
          icon: Icons.restart_alt_rounded,
          title: 'Leave Recall',
          subtitle: 'Request a recall',
          tint: const Color(0xFF13A88A),
          onTap: () => Get.to(() => LeaveRecallScreen()),
        ),
      ),
    ]);
  }

  Widget _serviceTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color tint,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _panel(context, radius: 19),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const Spacer(),
              Icon(Icons.north_east_rounded, color: _muted(context), size: 18),
            ]),
            const SizedBox(height: 10),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _ink(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _muted(context), fontSize: 10.5, height: 1.3)),
          ]),
        ),
      ),
    );
  }

  // Calendar-like request timeline: requested_date is used for the date marker.
  // The appointment timestamp is not assumed to be the actual leave date.
  DateTime? _requestDate(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;
    for (final pattern in <String>['dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } catch (_) {}
    }
    return null;
  }

  Color _requestTint(String type, String status) {
    final normalizedStatus = status.toLowerCase();
    final normalizedType = type.toLowerCase();
    if (normalizedStatus.contains('reject') ||
        normalizedStatus.contains('cancel')) {
      return const Color(0xFFFFE8E6);
    }
    if (normalizedStatus.contains('pending') ||
        normalizedStatus.contains('progress')) {
      return const Color(0xFFFFF2DB);
    }
    if (normalizedType.contains('casual')) return const Color(0xFFEDE9FF);
    if (normalizedType.contains('medical') || normalizedType.contains('sick')) {
      return const Color(0xFFFFE8DF);
    }
    if (normalizedType.contains('annual')) return const Color(0xFFE4F4EF);
    return const Color(0xFFE8F0FF);
  }

  Color _requestAccent(String type, String status) {
    final normalizedStatus = status.toLowerCase();
    final normalizedType = type.toLowerCase();
    if (normalizedStatus.contains('reject') ||
        normalizedStatus.contains('cancel')) {
      return const Color(0xFFEA7169);
    }
    if (normalizedStatus.contains('pending') ||
        normalizedStatus.contains('progress')) {
      return const Color(0xFFEAB449);
    }
    if (normalizedType.contains('casual')) return const Color(0xFF8263EE);
    if (normalizedType.contains('medical') || normalizedType.contains('sick')) {
      return const Color(0xFFF47861);
    }
    if (normalizedType.contains('annual')) return const Color(0xFF30AE86);
    return const Color(0xFF4384E8);
  }

  Widget _requests(BuildContext context) {
    if (controller.isLoadingRequests.value) {
      return Container(
        height: 116,
        decoration: _panel(context),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (controller.leaveRequests.isEmpty) {
      return _empty(context, Icons.event_busy_outlined, 'No recent requests',
          'New leave applications will appear here.');
    }

    final dark = _dark(context);
    final requests = controller.leaveRequests.take(5).toList();

    return Column(
      children: List.generate(requests.length, (index) {
        final leave = requests[index];
        final type = (leave['category_name'] ?? 'Leave').toString().trim();
        final status =
            (leave['approved_status_1'] ?? 'PENDING').toString().trim();
        final halfDay = controller.halfDayText(leave['is_half_day']);
        final formattedDate = controller.formatDate(leave['requested_date']);
        final rawDate = _requestDate(leave['requested_date']);
        final dateDay =
            rawDate == null ? '—' : DateFormat('dd').format(rawDate);
        final dateMonth = rawDate == null
            ? 'DATE'
            : DateFormat('MMM').format(rawDate).toUpperCase();
        final dateYear =
            rawDate == null ? '' : DateFormat('yyyy').format(rawDate);
        final accent = _requestAccent(type, status);
        final tint = _requestTint(type, status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 51,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(dateDay,
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        )),
                    const SizedBox(height: 2),
                    Text(dateMonth,
                        style: TextStyle(
                          color: _muted(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        )),
                    if (dateYear.isNotEmpty)
                      Text(dateYear,
                          style: TextStyle(
                            color: _muted(context),
                            fontSize: 9,
                          )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.to(() => LeaveRequestDetailPage(
                          leaveData: leave,
                          employeeId: controller.employeeId.value,
                        )),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1D2837) : tint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dark
                              ? accent.withOpacity(0.32)
                              : accent.withOpacity(0.08),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 39,
                            width: 39,
                            decoration: BoxDecoration(
                              color: dark
                                  ? accent.withOpacity(0.20)
                                  : accent.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(controller.leaveIcon(type),
                                color: dark ? accent : accent, size: 19),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(type.isEmpty ? 'Leave' : type,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _ink(context),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          )),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded,
                                        size: 17, color: Color(0xFF8390A3)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('Requested $formattedDate',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _muted(context),
                                      fontSize: 10.5,
                                    )),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(halfDay,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _muted(context),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? accent.withOpacity(0.18)
                                            : Colors.white.withOpacity(0.74),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Text(status.toUpperCase(),
                                          style: TextStyle(
                                            color: dark
                                                ? accent
                                                : controller
                                                    .statusColor(status),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _empty(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: _panel(context),
      child: Column(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: _blue, size: 23),
        ),
        const SizedBox(height: 10),
        Text(title,
            style: TextStyle(
                color: _ink(context),
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted(context), fontSize: 11)),
      ]),
    );
  }
}
