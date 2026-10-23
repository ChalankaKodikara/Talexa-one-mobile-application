import 'package:corehris/theme/theme.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';

class LeaveApprovedCard extends StatelessWidget {
  final String employeeName;
  final String employeeNumber;
  final String leaveType;
  final String applyeddate;
  final String daypart;
  final String status;
  final String reason;

  const LeaveApprovedCard({
    super.key,
    required this.employeeName,
    required this.employeeNumber,
    required this.leaveType,
    required this.applyeddate,
    required this.status,
    required this.reason,
    required this.daypart,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      case 'NOT APPROVED':
        return AppColors.primary2;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (status == 'NOT APPROVED') {
      return SizedBox.shrink();
    }
    return InkWell(
      onTap: () {
        _showApprovalDialog(context);
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  // First column: Employee Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          employeeName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'Applied Date: $applyeddate',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'Employee No: $employeeNumber',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        SizedBox(height: screenWidth * 0.02),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.015,
                              horizontal: screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context) {
    AppAlert.show(
      context: context,
      title: 'Leave Approval',
      message: status,
      type: status == 'APPROVED'
          ? AppAlertType.success
          : status == 'REJECTED'
              ? AppAlertType.error
              : AppAlertType.warning,
      details: [
        AppAlert.detail('Leave Type', leaveType),
        AppAlert.detail('Employee', employeeName),
        AppAlert.detail('Day Part', daypart),
        AppAlert.detail('Reason', reason),
      ],
    );
  }
}
