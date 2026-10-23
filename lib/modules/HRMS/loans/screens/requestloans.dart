// ignore_for_file: sort_child_properties_last

import 'package:corehris/modules/HRMS/loans/controllers/requestloans.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoanRequestPage extends StatelessWidget {
  const LoanRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoanRequestController());

    return Scaffold(
      appBar: AppBar(title: const Text("Loan Apply")),
      body: Obx(() {
        if (controller.isLoading.value && controller.loanTypes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 🔹 LOAN TYPE
              DropdownButtonFormField<int>(
                value: controller.selectedLoanTypeId.value,
                items: controller.loanTypes
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e['id'],
                        child: Text(e['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.selectedLoanTypeId.value = v,
                decoration: InputDecoration(
                  labelText: "Loan Type",
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 🔹 AUTO DETAILS
              Obx(() => _info("Amount Type", controller.amountType.value)),
              Obx(() => _info("Loan Amount", controller.loanAmount.value)),
              Obx(() =>
                  _info("Duration (Months)", controller.timePeriod.value)),
              Obx(() =>
                  _info("Interest Rate (%)", controller.loanInterest.value)),

              const SizedBox(height: 20),

              /// 🔹 GUARANTORS
              Obx(() {
                if (!controller.isGuarantorRequired) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    TextFormField(
                      controller: controller.guarantor1NameCtrl,
                      decoration: InputDecoration(
                        labelText: "Guarantor 1 Name",
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.guarantor1ContactCtrl,
                      decoration: InputDecoration(
                        labelText: "Guarantor 1 Contact",
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.guarantor2NameCtrl,
                      decoration: InputDecoration(
                        labelText: "Guarantor 2 Name",
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.guarantor2ContactCtrl,
                      decoration: InputDecoration(
                        labelText: "Guarantor 2 Contact",
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              /// 🔹 SUBMIT
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.submitLoanRequest,
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Submit Loan Request",
                              style: TextStyle(color: Colors.white),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isLoading.value
                            ? Colors.grey
                            : AppColors.primary2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value.isEmpty ? "-" : value),
        ],
      ),
    );
  }
}
