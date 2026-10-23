// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:corehris/theme/theme.dart';
import 'package:corehris/modules/HRMS/main_screens/teamscreen/controllers/teampage_con.dart';

class TeamPage extends StatelessWidget {
  TeamPage({super.key});

  final TeamPageController controller = Get.put(TeamPageController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Team Presence',
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// =================================================
          /// SUMMARY / TABS
          /// =================================================

          _buildPresenceTabs(
            context,
          ),

          /// =================================================
          /// SEARCH
          /// =================================================

          _buildSearchBar(
            context,
          ),

          /// =================================================
          /// EMPLOYEE LIST
          /// =================================================

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorState(
                  context,
                );
              }

              final list = controller.currentMembers;

              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  color: AppColors.primary1,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                      ),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              _emptyIcon(),
                              size: 48,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              controller.emptyMessage,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
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

              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppColors.primary1,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    20,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: 10,
                  ),
                  itemBuilder: (context, index) {
                    final member = list[index];

                    if (controller.selectedTab.value ==
                        TeamPresenceTab.onLeave) {
                      return _buildLeaveCard(
                        context,
                        member,
                      );
                    }

                    return _buildAttendanceCard(
                      context,
                      member,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABS
  // ==========================================================

  Widget _buildPresenceTabs(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          4,
        ),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2236) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTab(
                context: context,
                label: 'Present',
                count: controller.presentCount,
                icon: Icons.how_to_reg_rounded,
                tab: TeamPresenceTab.present,
                color: Colors.green,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: _buildTab(
                context: context,
                label: 'Absent',
                count: controller.absentCount,
                icon: Icons.person_off_rounded,
                tab: TeamPresenceTab.absent,
                color: Colors.red,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: _buildTab(
                context: context,
                label: 'On Leave',
                count: controller.leaveCount,
                icon: Icons.beach_access_rounded,
                tab: TeamPresenceTab.onLeave,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required int count,
    required IconData icon,
    required TeamPresenceTab tab,
    required Color color,
  }) {
    final theme = Theme.of(context);

    final selected = controller.selectedTab.value == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        controller.changeTab(tab);
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: selected
              ? Border.all(
                  color: color.withOpacity(
                    0.35,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _buildSearchBar(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        8,
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or employee no',
          prefixIcon: Icon(
            Icons.search,
            color: theme.iconTheme.color,
          ),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ??
              (isDark
                  ? const Color(
                      0xFF1A2236,
                    )
                  : Colors.white),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(
              color: AppColors.primary1,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ATTENDANCE CARD
  // ==========================================================

  Widget _buildAttendanceCard(
    BuildContext context,
    TeamMember member,
  ) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final status = controller.getStatus(member);

    final statusColor = controller.statusColor(
      status,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.25 : 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withOpacity(
                    0.12,
                  ),
                  child: Icon(
                    status == AttendanceStatus.absent
                        ? Icons.person_off_rounded
                        : Icons.person_rounded,
                    color: statusColor,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                /// Name / Employee No
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Employee No: ${member.employeeNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary1,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                /// Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(
                      isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    border: Border.all(
                      color: statusColor.withOpacity(
                        0.35,
                      ),
                    ),
                  ),
                  child: Text(
                    controller.statusText(
                      status,
                    ),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTimeItem(
                    context,
                    icon: Icons.login_rounded,
                    title: 'Check In',
                    value: controller.formatTime(
                      member.checkIn,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: _buildTimeItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Check Out',
                    value: controller.formatTime(
                      member.checkOut,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary1,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // LEAVE CARD
  // ==========================================================

  Widget _buildLeaveCard(
    BuildContext context,
    TeamMember member,
  ) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    const leaveColor = Colors.blue;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: leaveColor.withOpacity(
            0.25,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.25 : 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: leaveColor.withOpacity(
                    0.12,
                  ),
                  child: const Icon(
                    Icons.beach_access_rounded,
                    color: leaveColor,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Employee No: ${member.employeeNo}',
                        style: const TextStyle(
                          color: AppColors.primary1,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: leaveColor.withOpacity(
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    border: Border.all(
                      color: leaveColor.withOpacity(
                        0.3,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Approved',
                    style: TextStyle(
                      color: leaveColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),

            const SizedBox(
              height: 12,
            ),

            /// Leave type
            _buildLeaveInfoRow(
              context,
              icon: Icons.event_available_rounded,
              title: 'Leave Type',
              value: member.leaveType ?? 'Leave',
            ),

            if (member.leaveWeight != null) ...[
              const SizedBox(
                height: 8,
              ),
              _buildLeaveInfoRow(
                context,
                icon: Icons.schedule_rounded,
                title: 'Leave Amount',
                value: _formatLeaveWeight(
                  member.leaveWeight!,
                ),
              ),
            ],

            if (member.leaveReason != null &&
                member.leaveReason!.trim().isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              _buildLeaveInfoRow(
                context,
                icon: Icons.notes_rounded,
                title: 'Reason',
                value: member.leaveReason!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.blue,
        ),
        const SizedBox(
          width: 8,
        ),
        SizedBox(
          width: 85,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(
                0.55,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildErrorState(
    BuildContext context,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppColors.primary1,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
          ),
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 50,
          ),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  IconData _emptyIcon() {
    switch (controller.selectedTab.value) {
      case TeamPresenceTab.present:
        return Icons.groups_rounded;

      case TeamPresenceTab.absent:
        return Icons.person_off_rounded;

      case TeamPresenceTab.onLeave:
        return Icons.beach_access_rounded;
    }
  }

  String _formatLeaveWeight(
    double weight,
  ) {
    if (weight == 1) {
      return 'Full Day';
    }

    if (weight == 0.5) {
      return 'Half Day';
    }

    if (weight == 0.25) {
      return 'Short Leave';
    }

    return '$weight Day';
  }
}
