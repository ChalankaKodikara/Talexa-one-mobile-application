// ignore_for_file: library_private_types_in_public_api

import 'package:corehris/modules/HRMS/loans/controllers/loanstatus.dart';
import 'package:corehris/modules/HRMS/loans/screens/requestloans.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LoanStatusPage extends StatefulWidget {
  const LoanStatusPage({super.key});

  @override
  _LoanStatusPageState createState() => _LoanStatusPageState();
}

class _LoanStatusPageState extends State<LoanStatusPage> {
  final LoanStatusController controller = Get.put(LoanStatusController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Applications'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.loanRequests.isEmpty) {
          return const Center(
            child: Text(
              'No loan applications available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return _buildLoanList();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const LoanRequestPage()),
        child: const Icon(Icons.add),
        tooltip: 'Request Loan',
      ),
    );
  }

  /// ===============================
  /// LOAN LIST
  /// ===============================
  Widget _buildLoanList() {
    return ListView.builder(
      itemCount: controller.loanRequests.length,
      itemBuilder: (context, index) {
        final loan = controller.loanRequests[index];

        final status = loan['approval_status'] ?? 'UNKNOWN';
        final statusColor = _statusColor(status);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: statusColor, width: 6),
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 34,
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _loanDetails(loan, status, statusColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ===============================
  /// LOAN DETAILS
  /// ===============================
  Widget _loanDetails(
    Map<String, dynamic> loan,
    String status,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Loan Type Name
        Text(
          loan['loanType']?['name'] ?? 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),

        Text('Amount: Rs. ${loan['applied_amount']}'),
        Text('Duration: ${loan['duration_months']} months'),

        Text(
          'Interest: ${loan['interest_rate']}% • ${loan['calculation_type']}',
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 6),

        /// Status
        Row(
          children: [
            const Text('Status: '),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        Text(
          'Applied on: ${_formatDate(loan['applied_date'])}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  /// ===============================
  /// HELPERS
  /// ===============================
  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal());
    } catch (_) {
      return date;
    }
  }
}
