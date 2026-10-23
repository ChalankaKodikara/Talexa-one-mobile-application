// ignore_for_file: prefer_const_constructors, depend_on_referenced_packages, use_super_parameters

import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_req_con.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveRequestPage extends StatelessWidget {
  final LeaveRequestController controller = Get.put(LeaveRequestController());
  final List<Map<String, dynamic>> selectedDates;

  LeaveRequestPage({required this.selectedDates, Key? key}) : super(key: key) {
    controller.initializeRequestedDates(selectedDates);
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.cardColor;
    final softColor =
        isDark ? const Color(0xFF182235) : const Color(0xFFF8FAFC);
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.7)),
    );

    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: cs.primary, width: 1.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            labelText: "Covering Employee",
            hintText: "Search by name, ID or designation",
            prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
            filled: true,
            fillColor: softColor,
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: focusBorder,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            labelStyle: TextStyle(
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: secondaryText.withOpacity(0.8),
            ),
          ),
          onChanged: controller.onSearchChanged,
        ),
        Obx(() {
          if (controller.searchQuery.value.length < 2) {
            return const SizedBox.shrink();
          }

          final shadowColor = Colors.black.withOpacity(
            isDark ? 0.20 : 0.08,
          );

          return Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: controller.isSearchingEmployees.value
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  )
                : controller.searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          "No employees found",
                          style: TextStyle(color: secondaryText),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: controller.searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.35),
                        ),
                        itemBuilder: (_, index) {
                          final emp = controller.searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: cs.primary.withOpacity(
                                isDark ? 0.22 : 0.12,
                              ),
                              child: Text(
                                "${emp['employee_fullname'] ?? 'U'}"
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              "${emp['employee_fullname']}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                            subtitle: Text(
                              "${emp['employee_no']} • ${emp['designation_name'] ?? ''}",
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              controller.addCoveringEmployee(emp);
                            },
                          );
                        },
                      ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedEmployees(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final softColor =
        isDark ? const Color(0xFF182235) : const Color(0xFFF8FAFC);

    return Obx(() {
      if (controller.selectedCoveringEmployees.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "No covering employees selected",
            style: TextStyle(color: secondaryText),
          ),
        );
      }

      return Column(
        children: controller.selectedCoveringEmployees.map((emp) {
          final empNo = emp['employee_no'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary.withOpacity(
                        isDark ? 0.22 : 0.12,
                      ),
                      child: Text(
                        "${emp['employee_fullname'] ?? 'U'}"
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${emp['employee_fullname']}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.redAccent),
                      onPressed: () => controller.removeCoveringEmployee(empNo),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    "$empNo • ${emp['designation_name'] ?? ''}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _timePicker(
                      context,
                      label: (emp['start_time'] ?? '').toString().isEmpty
                          ? "Start Time"
                          : emp['start_time'],
                      onTap: () => _pickTime(context, empNo, isStart: true),
                    ),
                    const SizedBox(width: 12),
                    _timePicker(
                      context,
                      label: (emp['end_time'] ?? '').toString().isEmpty
                          ? "End Time"
                          : emp['end_time'],
                      onTap: () => _pickTime(context, empNo, isStart: false),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _timePicker(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            border: Border.all(color: cs.primary.withOpacity(0.70)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    String empNo, {
    required bool isStart,
  }) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      controller.setTime(empNo, isStart: isStart, time: t.format(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth >= 720 ? 640.0 : screenWidth;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 16.0;
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final cardColor = theme.cardColor;
    final softColor =
        isDark ? const Color(0xFF182235) : const Color(0xFFF8FAFC);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.7)),
    );

    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: cs.primary, width: 1.4),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leave Request'),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onBackground,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                120,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        context,
                        "Selected Dates",
                        "Dates you are requesting leave for",
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.18 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: controller.requestedDates
                              .map(
                                (d) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: softColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          theme.dividerColor.withOpacity(0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: cs.primary.withOpacity(
                                          isDark ? 0.22 : 0.12,
                                        ),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (d['request_day'] ?? '')
                                                  .toString(),
                                              style: TextStyle(
                                                color: primaryText,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              d['is_half_day'] == 1
                                                  ? "Half Day"
                                                  : "Full Day",
                                              style: TextStyle(
                                                color: secondaryText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        context,
                        "Covering Employees",
                        "Select employees who will cover your work",
                      ),
                      const SizedBox(height: 12),
                      _buildSearchField(context),
                      const SizedBox(height: 10),
                      _buildSelectedEmployees(context),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        context,
                        "Reason for Leave",
                        "Provide a short reason for this request",
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.18 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          style: TextStyle(color: primaryText),
                          onChanged: (v) => controller.reason.value = v,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Ex: Personal work, medical, etc.",
                            filled: true,
                            fillColor: softColor,
                            border: fieldBorder,
                            enabledBorder: fieldBorder,
                            focusedBorder: focusBorder,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            hintStyle: TextStyle(
                              color: secondaryText.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        context,
                        "Attachments",
                        "Upload supporting files if required",
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.18 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DottedBorder(
                              child: InkWell(
                                onTap: controller.pickFiles,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 90,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: softColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.attach_file_rounded,
                                        color: cs.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Browse Files",
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: controller.attachedFiles
                                    .map(
                                      (file) => Chip(
                                        label: Text(
                                          file.split("/").last,
                                          style: TextStyle(color: primaryText),
                                        ),
                                        backgroundColor: cs.primary.withOpacity(
                                          isDark ? 0.22 : 0.12,
                                        ),
                                        deleteIconColor:
                                            primaryText.withOpacity(0.75),
                                        onDeleted: () => controller
                                            .attachedFiles
                                            .remove(file),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Obx(
                () => Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        disabledBackgroundColor: cs.primary.withOpacity(0.4),
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () => controller.submitLeaveRequest(
                                controller.username.value,
                              ),
                      child: controller.isSubmitting.value
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: cs.onPrimary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              "Submit Request",
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
