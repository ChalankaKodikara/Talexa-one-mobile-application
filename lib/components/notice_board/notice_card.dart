// ignore_for_file: prefer_const_constructors, depend_on_referenced_packages

import 'package:corehris/theme/theme.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';

class NoticeCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime date;

  const NoticeCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        AppAlert.show(
          context: context,
          title: title,
          message: description,
          type: AppAlertType.info,
          details: [
            AppAlert.detail(
              'Date',
              date.toLocal().toString().split(' ')[0],
            ),
          ],
        );
      },
      child: Card(
        color: AppColors.primary2,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: 8,
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notification_add_rounded,
                    color: AppColors.primary2,
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Date: ${date.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
