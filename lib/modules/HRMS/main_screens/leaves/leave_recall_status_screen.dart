import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_recall_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveRecallStatusScreen extends StatefulWidget {
  const LeaveRecallStatusScreen({
    super.key,
  });

  @override
  State<LeaveRecallStatusScreen> createState() =>
      _LeaveRecallStatusScreenState();
}

class _LeaveRecallStatusScreenState extends State<LeaveRecallStatusScreen> {
  late final LeaveRecallController controller;

  @override
  void initState() {
    super.initState();

    /// SAME CONTROLLER FOR BOTH SCREENS
    controller = Get.isRegistered<LeaveRecallController>()
        ? Get.find<LeaveRecallController>()
        : Get.put(
            LeaveRecallController(),
          );

    if (controller.recallRequests.isEmpty &&
        !controller.isLoadingRecalls.value) {
      Future.microtask(
        controller.refreshRecallStatus,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final Color appBarColor = isDark ? AppColors.darkSurface : Colors.white;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textColorSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: appBarColor,
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
              "Recall Status",
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
              "Track your submitted recall requests",
              style: TextStyle(
                fontSize: 11,
                color: secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: "Refresh",
              onPressed: controller.isLoadingRecalls.value
                  ? null
                  : controller.refreshRecallStatus,
              icon: controller.isLoadingRecalls.value
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
          onRefresh: controller.refreshRecallStatus,
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
              /// STATUS LIST
              /// =================================================

              Obx(
                () {
                  if (controller.isLoadingRecalls.value &&
                      controller.recallRequests.isEmpty) {
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

                  if (controller.filteredRecallRequests.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StatusEmptyState(
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
                      itemCount: controller.filteredRecallRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: 12,
                      ),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final recall = controller.filteredRecallRequests[index];

                        return _RecallStatusCard(
                          recall: recall,
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

    final Color surface = isDark ? AppColors.darkSurface : Colors.white;

    final Color input = isDark ? AppColors.darkCard : AppColors.lightBackground;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textColorSecondary;

    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF7C3AED,
                    ).withValues(
                      alpha: isDark ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: isDark
                        ? const Color(
                            0xFFC4B5FD,
                          )
                        : const Color(
                            0xFF7C3AED,
                          ),
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
                        "${controller.recallRequests.length} ${controller.recallRequests.length == 1 ? 'Recall Request' : 'Recall Requests'}",
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
                        "Follow Supervisor and HR approval progress.",
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
            controller: controller.statusSearchController,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: primaryText,
            ),
            decoration: InputDecoration(
              hintText: "Search category, status or reason",
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: Obx(
                () {
                  if (controller.statusSearchText.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    onPressed: () {
                      controller.statusSearchController.clear();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  );
                },
              ),
              filled: true,
              fillColor: input,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.hintColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: border,
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
          /// STATUS FILTERS
          /// ----------------------------------------------------

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _FilterChip(
                    text: "All",
                    selected: controller.selectedRecallStatus.value == "ALL",
                    onTap: () {
                      controller.setRecallStatusFilter(
                        "ALL",
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _FilterChip(
                    text: "Supervisor",
                    selected: controller.selectedRecallStatus.value ==
                        "PENDING_SUPERVISOR",
                    onTap: () {
                      controller.setRecallStatusFilter(
                        "PENDING_SUPERVISOR",
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _FilterChip(
                    text: "HR",
                    selected:
                        controller.selectedRecallStatus.value == "PENDING_HR",
                    onTap: () {
                      controller.setRecallStatusFilter(
                        "PENDING_HR",
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _FilterChip(
                    text: "Recalled",
                    selected:
                        controller.selectedRecallStatus.value == "RECALLED",
                    onTap: () {
                      controller.setRecallStatusFilter(
                        "RECALLED",
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _FilterChip(
                    text: "Rejected",
                    selected:
                        controller.selectedRecallStatus.value == "REJECTED",
                    onTap: () {
                      controller.setRecallStatusFilter(
                        "REJECTED",
                      );
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          Obx(
            () {
              final filtered = controller.statusSearchText.value.isNotEmpty ||
                  controller.selectedRecallStatus.value != "ALL";

              if (!filtered) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.clearRecallStatusFilters,
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
/// RECALL STATUS CARD
/// ============================================================

class _RecallStatusCard extends StatelessWidget {
  const _RecallStatusCard({
    required this.recall,
    required this.controller,
    required this.isDark,
  });

  final Map<String, dynamic> recall;

  final LeaveRecallController controller;

  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    final category = controller.getCategoryName(
      recall,
    );

    final rawStatus = controller.getRecallStatus(
      recall,
    );

    final status = controller.getRecallStatusText(
      recall,
    );

    final stage = controller.getRecallStage(
      recall,
    );

    final leaveDate = controller.getRecallLeaveDateText(
      recall,
    );

    final requestedAt = controller.getRecallRequestedDateText(
      recall,
    );

    final supervisorStatus = controller.getSupervisorStatus(
      recall,
    );

    final hrStatus = controller.getHrStatus(
      recall,
    );

    final originalReason = controller.getOriginalLeaveReasonFromRecall(
      recall,
    );

    final recallReason = controller.getRecallReason(
      recall,
    );

    final remarks = controller.getRecallRemarks(
      recall,
    );

    final supervisorReason = controller.getSupervisorReason(
      recall,
    );

    final hrReason = controller.getHrReason(
      recall,
    );

    final recalledAt = controller.getRecalledAtText(
      recall,
    );

    final Color cardColor = isDark ? AppColors.darkCard : Colors.white;

    final Color borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textColorPrimary;

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
          /// HEADER
          /// ----------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF7C3AED,
                  ).withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  Icons.settings_backup_restore_rounded,
                  color: isDark
                      ? const Color(
                          0xFFC4B5FD,
                        )
                      : const Color(
                          0xFF7C3AED,
                        ),
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
                      height: 7,
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _RecallStatusChip(
                          status: rawStatus,
                          text: status,
                          isDark: isDark,
                        ),
                        _StageChip(
                          text: stage,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          _StatusInfoItem(
            icon: Icons.calendar_today_rounded,
            title: "Leave Date",
            value: leaveDate,
            isDark: isDark,
          ),

          const SizedBox(
            height: 12,
          ),

          _StatusInfoItem(
            icon: Icons.schedule_rounded,
            title: "Requested At",
            value: requestedAt,
            isDark: isDark,
          ),

          if (originalReason.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _StatusInfoItem(
              icon: Icons.description_outlined,
              title: "Original Leave Reason",
              value: originalReason,
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

          Text(
            "Approval Progress",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _ApprovalStatusRow(
            title: "Supervisor",
            status: controller.getSupervisorStatusText(
              recall,
            ),
            rawStatus: supervisorStatus,
            isDark: isDark,
          ),

          const SizedBox(
            height: 8,
          ),

          _ApprovalStatusRow(
            title: "HR",
            status: controller.getHrStatusText(
              recall,
            ),
            rawStatus: hrStatus,
            isDark: isDark,
          ),

          if (supervisorReason.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _StatusInfoItem(
              icon: Icons.person_outline_rounded,
              title: "Supervisor Reason",
              value: supervisorReason,
              isDark: isDark,
            ),
          ],

          if (hrReason.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _StatusInfoItem(
              icon: Icons.business_center_outlined,
              title: "HR Reason",
              value: hrReason,
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

          if (recallReason.isNotEmpty)
            _StatusInfoItem(
              icon: Icons.settings_backup_restore_rounded,
              title: "Recall Reason",
              value: recallReason,
              isDark: isDark,
            ),

          if (remarks.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _StatusInfoItem(
              icon: Icons.comment_outlined,
              title: "Remarks",
              value: remarks,
              isDark: isDark,
            ),
          ],

          if (recalledAt.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _StatusInfoItem(
              icon: Icons.check_circle_outline_rounded,
              title: "Recalled At",
              value: recalledAt,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

/// ============================================================
/// RECALL STATUS CHIP
/// ============================================================

class _RecallStatusChip extends StatelessWidget {
  const _RecallStatusChip({
    required this.status,
    required this.text,
    required this.isDark,
  });

  final String status;
  final String text;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    Color background;
    Color foreground;

    final normalized = status.toUpperCase();

    if (normalized.contains(
      "REJECTED",
    )) {
      background = isDark
          ? const Color(
              0xFF3B161A,
            )
          : const Color(
              0xFFFEE2E2,
            );

      foreground = isDark
          ? const Color(
              0xFFFCA5A5,
            )
          : const Color(
              0xFFB91C1C,
            );
    } else if (normalized == "RECALLED" || normalized == "APPROVED") {
      background = isDark
          ? const Color(
              0xFF123524,
            )
          : const Color(
              0xFFDCFCE7,
            );

      foreground = isDark
          ? const Color(
              0xFF86EFAC,
            )
          : const Color(
              0xFF15803D,
            );
    } else if (normalized == "CANCELLED") {
      background = isDark
          ? AppColors.darkSurface
          : const Color(
              0xFFF3F4F6,
            );

      foreground = isDark
          ? AppColors.darkTextMuted
          : const Color(
              0xFF4B5563,
            );
    } else {
      background = isDark
          ? const Color(
              0xFF3A2611,
            )
          : const Color(
              0xFFFFF7ED,
            );

      foreground = isDark
          ? const Color(
              0xFFFDBA74,
            )
          : const Color(
              0xFFC2410C,
            );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ============================================================
/// STAGE CHIP
/// ============================================================

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(
                0xFF102A43,
              )
            : const Color(
                0xFFEFF6FF,
              ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark
              ? const Color(
                  0xFF93C5FD,
                )
              : const Color(
                  0xFF1D4ED8,
                ),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ============================================================
/// APPROVAL STATUS ROW
/// ============================================================

class _ApprovalStatusRow extends StatelessWidget {
  const _ApprovalStatusRow({
    required this.title,
    required this.status,
    required this.rawStatus,
    required this.isDark,
  });

  final String title;
  final String status;
  final String rawStatus;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    Color color;

    switch (rawStatus.toUpperCase()) {
      case "APPROVED":
        color = isDark
            ? const Color(
                0xFF86EFAC,
              )
            : const Color(
                0xFF15803D,
              );
        break;

      case "REJECTED":
        color = isDark
            ? const Color(
                0xFFFCA5A5,
              )
            : const Color(
                0xFFB91C1C,
              );
        break;

      case "PENDING":
        color = isDark
            ? const Color(
                0xFFFDBA74,
              )
            : const Color(
                0xFFC2410C,
              );
        break;

      default:
        color = isDark
            ? AppColors.darkTextMuted
            : const Color(
                0xFF6B7280,
              );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : const Color(
                0xFFF9FAFB,
              ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: isDark
            ? Border.all(
                color: AppColors.darkBorder,
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(
                        0xFF374151,
                      ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// INFO ITEM
/// ============================================================

class _StatusInfoItem extends StatelessWidget {
  const _StatusInfoItem({
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
                  color: valueColor,
                  fontWeight: FontWeight.w500,
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
/// FILTER CHIP
/// ============================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.text,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 150,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary1
                : isDark
                    ? AppColors.darkCard
                    : const Color(
                        0xFFF3F4F6,
                      ),
            border: !selected && isDark
                ? Border.all(
                    color: AppColors.darkBorder,
                  )
                : null,
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : isDark
                      ? AppColors.darkTextSecondary
                      : const Color(
                          0xFF4B5563,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// EMPTY STATE
/// ============================================================

class _StatusEmptyState extends StatelessWidget {
  const _StatusEmptyState({
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
                color: const Color(
                  0xFF7C3AED,
                ).withValues(
                  alpha: isDark ? 0.18 : 0.10,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 38,
                color: isDark
                    ? const Color(
                        0xFFC4B5FD,
                      )
                    : const Color(
                        0xFF7C3AED,
                      ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              "No recall requests",
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
              "Your submitted leave recall requests and approval progress will appear here.",
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
