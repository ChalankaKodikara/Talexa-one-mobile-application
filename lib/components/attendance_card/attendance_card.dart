import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AttendanceReportCard extends StatelessWidget {
  final String Id;
  final String inTime;
  final String outTime;
  final String inAddress;
  final String outAddress;

  AttendanceReportCard({
    required this.Id,
    required this.inTime,
    required this.outTime,
    required this.inAddress,
    required this.outAddress,
  });
  Color getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      case 'NOT APPROVED':
        return AppColors.primary2;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          color: Colors.white,
          margin: EdgeInsets.all(10.0),
          child: Padding(
            padding: EdgeInsets.all(15.0),
            child: Row(
              children: [
                // Left-side container based on status
                Container(
                  width: 10,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary2,
                        AppColors.primary1,
                      ],
                    ),
                  ),
                  // Color based on status
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Text(
                              '$Id',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20.0),
                            ),
                            SizedBox(width: 60),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'In Time:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary2,
                                          fontSize: 15.0),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      '$inTime',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Out Time:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                          fontSize: 15.0),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '$outTime',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'In Address:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary2,
                                      fontSize: 15.0),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '$inAddress',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.0),
                                ),
                                Spacer(),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Out Address:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontSize: 15.0),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '$outAddress',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.0),
                                ),
                                Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().moveY(duration: 900.ms));
  }
}
