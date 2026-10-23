import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardEmployeeTileController extends GetxController {
  var employeeFullName = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployeeName();
  }

  Future<void> loadEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    employeeFullName.value = prefs.getString("name") ?? "N/A";
  }
}

class DashboardEmployeeTile extends StatelessWidget {
  final DashboardEmployeeTileController controller =
      Get.put(DashboardEmployeeTileController());

  DashboardEmployeeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Generate initials from the employee's full name
      String initials = (controller.employeeFullName.value.isNotEmpty
              ? controller.employeeFullName.value
                  .split(" ")
                  .map((name) => name[0])
                  .join("")
              : "N/A")
          .toUpperCase();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular initials avatar
            Container(
              height: 50,
              width: 50,
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
                  fontSize: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Employee full name
            // Text(
            //   controller.employeeFullName.value,
            //   style: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //     color: Colors.black,
            //   ),
            // ),
          ],
        ),
      );
    });
  }
}
