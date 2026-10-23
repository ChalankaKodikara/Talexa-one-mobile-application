import 'package:corehris/modules/HRMS/main_screens/facilities/Claims/claim_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClaimApplyScreen extends StatelessWidget {
  final int claimConfigurationId;
  final String claimType;
  final double maxAmount;
  final int policyPeriodMonths;

  ClaimApplyScreen({
    super.key,
    required this.claimConfigurationId,
    required this.claimType,
    required this.maxAmount,
    required this.policyPeriodMonths,
  });

  final ClaimApplyController controller = Get.put(ClaimApplyController());

  @override
  Widget build(BuildContext context) {
    controller.claimConfigurationId = claimConfigurationId;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Apply $claimType Claim',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(
        () => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================
                // CLAIM INFO (M3 FLAT)
                // ======================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claimType,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maximum Claim Amount',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${maxAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Eligible once every $policyPeriodMonths months',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ======================
                // CLAIM AMOUNT FIELD
                // ======================
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Claim Amount',
                    prefixText: 'Rs. ',
                    hintText: 'Enter claim amount',
                    helperText:
                        'Maximum allowed: Rs. ${maxAmount.toStringAsFixed(2)}',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      controller.claimAmount.value = double.tryParse(v) ?? 0,
                ),

                const SizedBox(height: 20),

                // ======================
                // DOCUMENT UPLOAD
                // ======================
                OutlinedButton.icon(
                  onPressed: controller.pickDocuments,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Supporting Documents'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),

                const SizedBox(height: 12),

                // ======================
                // DOCUMENT LIST
                // ======================
                Expanded(
                  child: controller.documents.isEmpty
                      ? Center(
                          child: Text(
                            'No documents uploaded',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.outline),
                          ),
                        )
                      : ListView.separated(
                          itemCount: controller.documents.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: colors.outlineVariant),
                          itemBuilder: (context, index) {
                            final file = controller.documents[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(
                                file.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    controller.removeDocument(index),
                              ),
                            );
                          },
                        ),
                ),

                if (controller.error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.error.value,
                      style: TextStyle(color: colors.error),
                    ),
                  ),

                // ======================
                // SUBMIT BUTTON (M3)
                // ======================
                SafeArea(
                  top: false,
                  child: FilledButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Claim'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
