import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/modules/HRMS/main_screens/performance/controllers/performance.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late final PerformanceController controller;

  @override
  void initState() {
    super.initState();
    // ✅ create once (avoid re-put during rebuilds)
    controller = Get.put(PerformanceController());
  }

  // ================== PENDING SHEET ==================
  Widget buildPendingSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final dataList = controller.performanceData;

      return Column(
        children: [
          const SizedBox(height: 16),

          // VALID DATE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Valid Date :",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onBackground,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      "2025 January 25 – 2025 February 25",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 12),

          // HEADER ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "CRITERIA",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onBackground,
                    ),
                  ),
                  Text(
                    "MY VOTE",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // LIST
          Expanded(
            child: dataList.isEmpty
                ? Center(
                    child: Text(
                      "No criteria found",
                      style: TextStyle(color: cs.onBackground.withOpacity(0.7)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: dataList.length,
                    itemBuilder: (context, index) {
                      final data = dataList[index];

                      final shadowColor = Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.35 : 0.10,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: theme.dividerColor.withOpacity(0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onBackground,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chevron_left,
                                          color: cs.primary),
                                      onPressed: () =>
                                          controller.decrementScore(index),
                                    ),
                                    Text(
                                      '${data.score} / 5',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: cs.onBackground),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chevron_right,
                                          color: cs.primary),
                                      onPressed: () =>
                                          controller.incrementScore(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // SUBMIT BUTTON
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitPerformanceToBackend,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          "Submit Performance",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ================== SUBMITTED SHEET ==================
  Widget buildSubmittedSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      if (controller.submittedPerformances.isEmpty) {
        return Center(
          child: Text(
            "No submitted performance records",
            style: TextStyle(color: cs.onBackground.withOpacity(0.7)),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.submittedPerformances.length,
        itemBuilder: (context, index) {
          final submitted = controller.submittedPerformances[index];

          final shadowColor = Colors.black.withOpacity(
            theme.brightness == Brightness.dark ? 0.35 : 0.10,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              iconColor: cs.onBackground.withOpacity(0.8),
              collapsedIconColor: cs.onBackground.withOpacity(0.6),
              title: Row(
                children: [
                  Icon(Icons.insert_drive_file_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      submitted.month,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Submitted Date : ${submitted.submittedDate}",
                  style: TextStyle(color: cs.onBackground.withOpacity(0.65)),
                ),
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cs.onBackground.withOpacity(
                      theme.brightness == Brightness.dark ? 0.08 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("CRITERIA",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.onBackground)),
                      Text("MY VOTE",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.onBackground)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...submitted.criteria.map((item) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withOpacity(0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title']?.toString() ?? "-",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onBackground,
                            ),
                          ),
                        ),
                        Text(
                          item['score']?.toString() ?? "-",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: cs.error.withOpacity(0.12),
                    ),
                    onPressed: () =>
                        controller.deleteSubmittedPerformance(submitted.id),
                    child: const Text(
                      "Delete Performance",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      );
    });
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Performance', style: TextStyle(fontSize: 20)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor ??
              theme.scaffoldBackgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onBackground,
          bottom: TabBar(
            indicatorColor: cs.primary,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onBackground.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            tabs: const [
              Tab(text: 'Pending Sheet'),
              Tab(text: 'Submitted Sheet'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          return TabBarView(
            children: [
              buildPendingSheet(context),
              buildSubmittedSheet(context),
            ],
          );
        }),
      ),
    );
  }
}
