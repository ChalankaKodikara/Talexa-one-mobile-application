import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';

class LeaveApprovalCard extends StatelessWidget {
  final String employeeName;
  final String employeeNumber;
  final String leaveType;
  final String applyeddate;
  final String daypart;
  final String status;
  final String reason;
  final int leaveId;
  final Function(String status, String remarks) onStatusUpdate;

  const LeaveApprovalCard({
    super.key,
    required this.employeeName,
    required this.employeeNumber,
    required this.leaveType,
    required this.daypart,
    required this.applyeddate,
    required this.status,
    required this.reason,
    required this.leaveId,
    required this.onStatusUpdate,
  });

  static const Color _blue = Color(0xFF1769E8);
  static const Color _ink = Color(0xFF182237);
  static const Color _muted = Color(0xFF89919D);
  static const Color _border = Color(0xFFE8EDF4);

  @override
  Widget build(BuildContext context) {
    // Keep the original pending approval rule.
    if (status.trim().toUpperCase() != 'NOT APPROVED') {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color surface = isDark ? const Color(0xFF1B2638) : Colors.white;

    final Color textColor = isDark ? Colors.white : _ink;

    final Color secondaryColor = isDark ? const Color(0xFFA4AFC0) : _muted;

    final Color borderColor = isDark ? const Color(0xFF303D50) : _border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showApprovalDialog(context),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(
                          isDark ? 0.17 : 0.09,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 21,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employeeNumber,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: secondaryColor,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Divider(
                  height: 1,
                  color: borderColor,
                ),

                const SizedBox(height: 13),

                // Leave type and approval status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEAVE REQUEST',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 9,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            leaveType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF40351F)
                            : const Color(0xFFFFF3DF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Pending Approval',
                        style: TextStyle(
                          color: Color(0xFFBB810E),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Requested date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requested',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        applyeddate,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Optional day part
                if (daypart.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 15,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Day Part',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        daypart,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPROVAL CONFIRMATION POPUP
  // ============================================================

  void _showApprovalDialog(BuildContext context) {
    AppAlert.show(
      context: context,
      title: 'Leave Approval',
      message: 'Review this leave request before proceeding.',
      type: AppAlertType.confirm,
      details: [
        AppAlert.detail('Employee', employeeName),
        AppAlert.detail('Employee No', employeeNumber),
        AppAlert.detail('Leave Type', leaveType),
        AppAlert.detail('Requested Date', applyeddate),
        if (daypart.trim().isNotEmpty) AppAlert.detail('Day Part', daypart),
        AppAlert.detail('Reason', reason),
      ],
      actions: [
        AppAlertAction(
          label: 'Reject',
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).pop();

            // Existing callback unchanged.
            onStatusUpdate(
              'REJECTED',
              'Rejected by supervisor',
            );
          },
        ),
        AppAlertAction(
          label: 'Approve',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();

            // Existing callback unchanged.
            onStatusUpdate(
              'APPROVED',
              'Approved by supervisor',
            );
          },
        ),
      ],
    );
  }
}
