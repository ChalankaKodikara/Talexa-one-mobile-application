import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_recall_con.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leave_recall_status_screen.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveRecallScreen extends StatefulWidget {
  const LeaveRecallScreen({
    super.key,
  });

  @override
  State<LeaveRecallScreen> createState() => _LeaveRecallScreenState();
}

class _LeaveRecallScreenState extends State<LeaveRecallScreen> {
  late final LeaveRecallController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<LeaveRecallController>()
        ? Get.find<LeaveRecallController>()
        : Get.put(
            LeaveRecallController(),
          );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final Color surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textColorSecondary;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leave Recall",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              "Recall an upcoming approved leave",
              style: TextStyle(
                fontSize: 11,
                color: secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          /// ====================================================
          /// RECALL STATUS SCREEN
          /// ====================================================

          IconButton(
            tooltip: "Recall Status",
            onPressed: () {
              Get.to(
                () => const LeaveRecallStatusScreen(),
              );
            },
            icon: const Icon(
              Icons.history_rounded,
            ),
          ),

          /// ====================================================
          /// REFRESH
          /// ====================================================

          Obx(
            () => IconButton(
              tooltip: "Refresh",
              onPressed:
                  controller.isLoading.value ? null : controller.refreshLeaves,
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? const Color(
                                0xFF60A5FA,
                              )
                            : AppColors.primary1,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                    ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshLeaves,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// =================================================
              /// HEADER
              /// =================================================

              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                ),
              ),

              /// =================================================
              /// AVAILABLE LEAVES
              /// =================================================

              Obx(
                () {
                  if (controller.isLoading.value &&
                      controller.availableRecallLeaves.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: isDark
                              ? const Color(
                                  0xFF60A5FA,
                                )
                              : AppColors.primary1,
                        ),
                      ),
                    );
                  }

                  if (controller.filteredLeaveData.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _RecallEmptyState(
                        isDark: isDark,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      30,
                    ),
                    sliver: SliverList.separated(
                      itemCount: controller.filteredLeaveData.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: 12,
                      ),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final leave = controller.filteredLeaveData[index];

                        return _RecallLeaveCard(
                          leave: leave,
                          controller: controller,
                          isDark: isDark,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ============================================================
  /// HEADER
  /// ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    final Color inputColor =
        isDark ? AppColors.darkCard : AppColors.lightBackground;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textColorSecondary;

    final Color borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ----------------------------------------------------
          /// COUNT
          /// ----------------------------------------------------

          Obx(
            () => Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary1.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primary1,
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
                        "${controller.availableRecallLeaves.length} Available ${controller.availableRecallLeaves.length == 1 ? 'Leave' : 'Leaves'}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        "Only upcoming approved leave available for recall is shown.",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// ----------------------------------------------------
          /// SEARCH
          /// ----------------------------------------------------

          TextField(
            controller: controller.searchController,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: primaryText,
            ),
            decoration: InputDecoration(
              hintText: "Search category or reason",
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: Obx(
                () {
                  if (controller.searchText.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    onPressed: () {
                      controller.searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  );
                },
              ),
              filled: true,
              fillColor: inputColor,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.hintColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: const BorderSide(
                  color: AppColors.primary1,
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          /// ----------------------------------------------------
          /// DATE FILTERS
          /// ----------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _DateFilter(
                    title: "From",
                    date: controller.startDate.value,
                    onTap: () {
                      controller.pickDate(
                        context,
                        isStart: true,
                      );
                    },
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Obx(
                  () => _DateFilter(
                    title: "To",
                    date: controller.endDate.value,
                    onTap: () {
                      controller.pickDate(
                        context,
                        isStart: false,
                      );
                    },
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),

          Obx(
            () {
              final hasFilter = controller.startDate.value != null ||
                  controller.endDate.value != null ||
                  controller.searchText.value.isNotEmpty;

              if (!hasFilter) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.clearLeaveFilters,
                  icon: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    "Clear filters",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// LEAVE CARD
/// ============================================================

class _RecallLeaveCard extends StatelessWidget {
  const _RecallLeaveCard({
    required this.leave,
    required this.controller,
    required this.isDark,
  });

  final Map<String, dynamic> leave;

  final LeaveRecallController controller;

  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    final id = controller.getLeaveId(
      leave,
    );

    final category = controller.getCategoryName(
      leave,
    );

    final date = controller.getLeaveDateText(
      leave,
    );

    final reason = controller.getLeaveReason(
      leave,
    );

    final approvalStatus = controller.getLeaveApprovalText(
      leave,
    );

    final Color cardColor = isDark ? AppColors.darkCard : Colors.white;

    final Color borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textColorSecondary;

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.025,
                  ),
                  blurRadius: 12,
                  offset: const Offset(
                    0,
                    4,
                  ),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ----------------------------------------------------
          /// CATEGORY
          /// ----------------------------------------------------

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary1.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary1,
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
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(
                                0xFF123524,
                              )
                            : const Color(
                                0xFFDCFCE7,
                              ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        approvalStatus,
                        style: TextStyle(
                          color: isDark
                              ? const Color(
                                  0xFF86EFAC,
                                )
                              : const Color(
                                  0xFF15803D,
                                ),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          _InfoItem(
            icon: Icons.calendar_today_rounded,
            title: "Leave Date",
            value: date,
            isDark: isDark,
          ),

          if (reason.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _InfoItem(
              icon: Icons.notes_rounded,
              title: "Leave Reason",
              value: reason,
              isDark: isDark,
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          Divider(
            height: 1,
            color: borderColor,
          ),

          const SizedBox(
            height: 14,
          ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: Obx(
              () {
                final loading = controller.recallingLeaveId.value == id;

                return ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () {
                          controller.openRecallDialog(
                            context: context,
                            leave: leave,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary1,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(
                            0xFF263244,
                          )
                        : const Color(
                            0xFFE5E7EB,
                          ),
                    disabledForegroundColor: isDark
                        ? AppColors.darkTextMuted
                        : const Color(
                            0xFF9CA3AF,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.settings_backup_restore_rounded,
                        ),
                  label: Text(
                    loading ? "Submitting..." : "Recall Leave",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),

          /// Optional subtle secondary info
          if (isDark)
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
              ),
              child: Text(
                "",
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ============================================================
/// DATE FILTER
/// ============================================================

class _DateFilter extends StatelessWidget {
  const _DateFilter({
    required this.title,
    required this.date,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color background =
        isDark ? AppColors.darkCard : AppColors.lightBackground;

    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final Color text = date == null
        ? isDark
            ? AppColors.darkTextMuted
            : const Color(
                0xFF9CA3AF,
              )
        : isDark
            ? AppColors.darkTextPrimary
            : const Color(
                0xFF374151,
              );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.primary1,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  date == null
                      ? title
                      : "${date!.day.toString().padLeft(2, '0')}/"
                          "${date!.month.toString().padLeft(2, '0')}/"
                          "${date!.year}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// INFO ITEM
/// ============================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color iconBg = isDark
        ? AppColors.darkSurface
        : const Color(
            0xFFF3F4F6,
          );

    final Color muted = isDark
        ? AppColors.darkTextMuted
        : const Color(
            0xFF9CA3AF,
          );

    final Color valueColor = isDark
        ? AppColors.darkTextSecondary
        : const Color(
            0xFF374151,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(
              9,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: muted,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// EMPTY STATE
/// ============================================================

class _RecallEmptyState extends StatelessWidget {
  const _RecallEmptyState({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextMuted : AppColors.textColorSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary1.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 38,
                color: AppColors.primary1,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              "No leave available for recall",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              "Upcoming approved leave without an active recall request will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
