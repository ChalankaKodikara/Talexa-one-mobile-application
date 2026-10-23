import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';

class EmployeeTile extends StatelessWidget {
  final String employeeFullName;

  const EmployeeTile({
    super.key,
    required this.employeeFullName,
  });

  @override
  Widget build(BuildContext context) {
    // Generate initials from the employee's full name
    String initials = (employeeFullName.isNotEmpty
            ? employeeFullName.split(" ").map((name) => name[0]).join("")
            : "N/A")
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular initials avatar
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.primary2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 80,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Employee name
          // Text(
          //   employeeFullName.isNotEmpty ? employeeFullName : "N/A",
          //   style: const TextStyle(
          //     fontSize: 14,
          //     fontWeight: FontWeight.w600,
          //     color: Colors.black,
          //   ),
          // ),
        ],
      ),
    );
  }
}
