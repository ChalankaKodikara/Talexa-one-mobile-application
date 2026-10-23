import 'package:corehris/modules/HRMS/main_screens/facilities/Claims/claim_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/components/facilities_card/facilities_card.dart';
import 'package:corehris/components/facilities_card/claimtypes/facilitymapper.dart';
import 'package:corehris/modules/HRMS/main_screens/facilities/facilities_con.dart';

class FacilitiesScreen extends StatelessWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FacilitiesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Facilities',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: controller.refreshAll,
              child: const Text('Retry'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: controller.claimTypes.length,
          itemBuilder: (context, index) {
            final claim = controller.claimTypes[index];

            final ui = mapClaimToUI(
              claim.claimType,
              claim.claimAmount,
              claim.policyPeriodMonths,
            );

            return FacilityCard(
              title: ui.title,
              subtitle: ui.subtitle,
              bullets: ui.bullets,
              icon: ui.icon,
              accentColor: ui.color,
              onView: () {
                Get.to(
                  () => ClaimApplyScreen(
                    claimConfigurationId: claim.id,
                    claimType: claim.claimType,
                    maxAmount: claim.claimAmount,
                    policyPeriodMonths: claim.policyPeriodMonths,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
