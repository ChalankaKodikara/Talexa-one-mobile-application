// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:corehris/modules/HRMS/main_screens/noticeboard/controllers/notice.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late final NoticeBoardController noticeController;

  @override
  void initState() {
    super.initState();
    // ✅ prevent multiple Get.put on every build
    noticeController = Get.put(NoticeBoardController());
    // optional: if you want auto fetch here, uncomment
    // noticeController.fetchNotices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notice Board"),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onSurface,
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          await noticeController.fetchNotices();
        },
        child: Obx(() {
          if (noticeController.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final notices = noticeController.notices;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -----------------------------
                // HEADER
                // -----------------------------
                Text(
                  "Notice Board",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage and publish company announcements",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 20),

                // -----------------------------
                // SUMMARY CARDS
                // -----------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryCard(
                      context: context,
                      title: "Total Notices",
                      value: notices.length.toString(),
                      icon: LucideIcons.bell,
                      color: cs.primary,
                    ),
                    _summaryCard(
                      context: context,
                      title: "Active",
                      value: notices
                          .where((n) => n.status == "ACTIVE")
                          .length
                          .toString(),
                      icon: LucideIcons.activity,
                      color: AppColors.success,
                    ),
                    _summaryCard(
                      context: context,
                      title: "Inactive",
                      value: notices
                          .where((n) => n.status == "INACTIVE")
                          .length
                          .toString(),
                      icon: LucideIcons.closedCaption,
                      color: AppColors.danger,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // -----------------------------
                // NOTICE LIST (no edit/delete)
                // -----------------------------
                if (notices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        "No notices found",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                  )
                else
                  ...notices.map((n) {
                    return _noticeCard(
                      context: context,
                      title: n.title,
                      description: n.description,
                      date: n.updatedAt,
                      status: n.status,
                    );
                  }),

                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --------------------------------------------------
  // SUMMARY CARD (dark-mode ready)
  // --------------------------------------------------
  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final shadowColor = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.08,
    );

    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: shadowColor,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // NOTICE CARD (dark-mode ready)
  // --------------------------------------------------
  Widget _noticeCard({
    required BuildContext context,
    required String title,
    required String description,
    required DateTime? date,
    required String status,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final formattedDate = date != null
        ? DateFormat("dd/MM/yyyy, HH:mm:ss").format(date)
        : 'Unknown';

    final shadowColor = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.06,
    );

    final bool isActive = status == "ACTIVE";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: shadowColor,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Icon
          Row(
            children: [
              Icon(LucideIcons.bell, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // DATE
          Row(
            children: [
              Icon(
                LucideIcons.calendarDays,
                size: 16,
                color: cs.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.60),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // DESCRIPTION
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.4,
              color: cs.onSurface.withOpacity(0.88),
            ),
          ),

          const SizedBox(height: 18),

          // STATUS BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success.withOpacity(
                      theme.brightness == Brightness.dark ? 0.25 : 0.15,
                    )
                  : AppColors.danger.withOpacity(
                      theme.brightness == Brightness.dark ? 0.25 : 0.15,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isActive ? AppColors.success : AppColors.danger)
                    .withOpacity(0.35),
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isActive ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
