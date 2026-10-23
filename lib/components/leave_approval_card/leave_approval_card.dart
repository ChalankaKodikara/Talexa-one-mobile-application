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
  final Function(String status, String remarks)
      onStatusUpdate; // Callback function

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

  @override
  Widget build(BuildContext context) {
    // Only display the card if the status is 'Pending'
    if (status != 'NOT APPROVED') {
      return SizedBox.shrink(); // Return an empty widget if not pending
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
          padding: EdgeInsets.all(16.0),
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
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Request Date: $applyeddate',
                          style: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Employee No: $employeeNumber',
                          style: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.only(
                              left: 20, right: 20, top: 5, bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 15.0,
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
      type: AppAlertType.confirm,
      details: [
        AppAlert.detail('Leave Type', leaveType),
        AppAlert.detail('Employee', employeeName),
        AppAlert.detail('Requested', applyeddate),
        AppAlert.detail('Reason', reason),
      ],
      actions: [
        AppAlertAction(
          label: 'Reject',
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).pop();
            onStatusUpdate('REJECTED', 'Rejected by supervisor');
          },
        ),
        AppAlertAction(
          label: 'Approve',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();
            onStatusUpdate('APPROVED', 'Approved by supervisor');
          },
        ),
      ],
    );
  }
}
