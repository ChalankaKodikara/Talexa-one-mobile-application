import 'package:corehris/modules/HRMS/main_screens/facilities/claim_status_con.dart';
import 'package:corehris/modules/HRMS/main_screens/facilities/facilities_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClaimListScreen extends StatelessWidget {
  const ClaimListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClaimListController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Claims',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ==========================
      // APPLY CLAIM BUTTON (FAB)
      // ==========================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to facilities to choose claim type
          Get.to(() => const FacilitiesScreen());
        },
        icon: const Icon(Icons.add),
        label: const Text('Apply Claim'),
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: controller.refresh,
              child: const Text('Retry'),
            ),
          );
        }

        if (controller.claims.isEmpty) {
          return const Center(child: Text('No claims found'));
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: controller.claims.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final claim = controller.claims[index];
              final raw = controller.claimsRaw[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showClaimDetails(context, raw),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              claim.claimType,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Amount: Rs. ${claim.claimAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Requested: ${claim.requestedDate}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              statusColor(claim.finalStatus).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          claim.finalStatus.toUpperCase(),
                          style: TextStyle(
                            color: statusColor(claim.finalStatus),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // ==========================================================
  // CLAIM DETAILS POP-UP (BOTTOM SHEET)
  // ==========================================================
  void _showClaimDetails(BuildContext context, Map<String, dynamic> claim) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final docs = claim['EmployeeClaimDocuments'] as List;
        final config = claim['ClaimConfiguration'];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  _section(theme, 'Claim Information', [
                    _row('Type', config['claim_type']),
                    _row('Requested Amount', 'Rs. ${claim['claim_amount']}'),
                    _row('Requested Date', claim['claim_requested_date']),
                    _row('Final Status', claim['final_status']),
                  ]),
                  _section(theme, 'Approval Level 1', [
                    _row('Status', claim['approval_status_1']),
                    _row('Approved By', claim['approval_1_by'] ?? '-'),
                    _row('Remarks', claim['approval_1_remarks'] ?? '-'),
                  ]),
                  _section(theme, 'Approval Level 2', [
                    _row('Status', claim['approval_status_2']),
                    _row('Approved By', claim['approval_2_by'] ?? '-'),
                    _row('Remarks', claim['approval_2_remarks'] ?? '-'),
                  ]),
                  _section(
                    theme,
                    'Documents',
                    docs.isEmpty
                        ? [const Text('No documents uploaded')]
                        : docs
                            .map<Widget>(
                              (d) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(
                                  d['document_path'].split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================
  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
