// ignore_for_file: prefer_const_constructors, depend_on_referenced_packages

import 'package:corehris/modules/HRMS/salary/controllers/salary.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SalaryScreenController controller = Get.put(SalaryScreenController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF111827),
            Color(0xFF0B1220),
          ]
        : const [
            Color(0xFFF8FAFF),
            Color(0xFFF2F5FB),
            Color(0xFFEFF4FF),
          ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: const Text(
          'Payslip',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: BackButton(color: theme.appBarTheme.foregroundColor),
        actions: [
          IconButton(
            onPressed: controller.downloadPayslip,
            tooltip: 'Download Payslip',
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          color: AppColors.primary1,
          onRefresh: () async => controller.fetchSalary(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topFilterBar(context, controller, isDark),
                  const SizedBox(height: 16),
                  if (controller.isLoading.value)
                    _loadingState()
                  else if (controller.salaryDetails.isEmpty)
                    _emptyState(context)
                  else
                    _modernPayslip(context, controller),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _topFilterBar(
    BuildContext context,
    SalaryScreenController controller,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => controller.openDatePicker(context),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(isDark ? 0.86 : 1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.primary1.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary1,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${controller.selectedMonthLabel} ${controller.selectedYear.value}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: controller.fetchSalary,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary2,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text(
              'View',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary1),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.88 : 1),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary1.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary1,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No salary records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a month and year to view your payslip details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernPayslip(
    BuildContext context,
    SalaryScreenController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final salary = Map<String, dynamic>.from(controller.salaryDetails);

    final allowances = _extractAllowanceRows(salary);
    final deductions = _extractDeductionRows(salary);

    return Column(
      children: [
        _heroCard(context, salary, isDark),
        const SizedBox(height: 16),
        _summaryGrid(context, salary, isDark),
        const SizedBox(height: 16),
        _employeeInfoCard(context, salary, isDark),
        const SizedBox(height: 16),
        _sectionCard(
          context: context,
          title: "Earnings",
          icon: Icons.trending_up_rounded,
          titleColor: AppColors.success,
          children: [
            _buildAmountRow(context, "Basic Salary", salary['basic_salary']),
            _buildAmountRow(context, "COLA", salary['cola']),
            _buildAmountRow(context, "Overtime Pay", salary['overtime_pay']),
            _buildAmountRow(
                context, "Salary Arrears", salary['salary_arrears']),
            _buildAmountRow(
              context,
              "Reimbursement",
              salary['reimbursement_amount'],
            ),
            _buildAmountRow(context, "Leave Encash", salary['leave_encash']),
            _buildAmountRow(
              context,
              "Spectacle Allowance",
              salary['spectacle_allowance'],
            ),
            ...allowances.map(
              (a) => _buildAmountRow(context, a['label'], a['value']),
            ),
            const SizedBox(height: 8),
            _buildStrongAmountRow(
              context,
              "Total Allowances",
              salary['total_allowances'],
            ),
            _buildStrongAmountRow(context, "Gross Pay", salary['gross_pay']),
            _buildStrongAmountRow(
              context,
              "Total Earnings",
              salary['total_earnings'],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context: context,
          title: "Deductions",
          icon: Icons.trending_down_rounded,
          titleColor: AppColors.danger,
          children: [
            _buildAmountRow(
                context, "Salary Advance", salary['salary_advance']),
            _buildAmountRow(
              context,
              "Loan Installment",
              salary['loan_installment'],
            ),
            _buildAmountRow(
              context,
              "Calculated No Pay",
              salary['calculated_nopay'],
            ),
            _buildAmountRow(context, "Per Day No Pay", salary['per_day_nopay']),
            _buildAmountRow(
              context,
              "Intern Deduction",
              salary['intern_deduction'],
            ),
            ...deductions.map(
              (d) => _buildAmountRow(context, d['label'], d['value']),
            ),
            const SizedBox(height: 8),
            _buildStrongAmountRow(
              context,
              "Total Deductions",
              salary['total_deductions'],
            ),
            _buildStrongAmountRow(context, "Net Pay", salary['net_pay']),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context: context,
          title: "Contributions",
          icon: Icons.account_balance_wallet_rounded,
          titleColor: AppColors.primary1,
          children: [
            _buildAmountRow(context, "EPF Base", salary['epf_base']),
            _buildAmountRow(context, "EPF 8%", salary['epf_8']),
            _buildAmountRow(context, "EPF 12%", salary['epf_12']),
            _buildAmountRow(context, "ETF 3%", salary['etf_3']),
            _buildAmountRow(context, "EPF Employer", salary['epf_employer']),
          ],
        ),
      ],
    );
  }

  Widget _heroCard(
      BuildContext context, Map<String, dynamic> salary, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ]
              : const [
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                  Color(0xFF60A5FA),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary1.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${_monthName(salary['month'])} ${salary['year'] ?? ''} Payslip",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(salary['payroll_status']),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            "Net Salary",
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _money(salary['net_pay']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            (salary['employee_fullname'] ??
                    salary['employee_calling_name'] ??
                    '-')
                .toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${salary['employee_no'] ?? '-'} • ${(salary['job_title'] ?? '-').toString().trim()}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(
      BuildContext context, Map<String, dynamic> salary, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            context,
            title: "Gross Pay",
            value: _money(salary['gross_pay']),
            icon: Icons.account_balance_wallet_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStatCard(
            context,
            title: "Deductions",
            value: _money(salary['total_deductions']),
            icon: Icons.remove_circle_outline_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.88 : 1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary1, size: 20),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeInfoCard(
    BuildContext context,
    Map<String, dynamic> salary,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.88 : 1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Employee Information",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _infoTile(context, "Employee Name",
              salary['employee_fullname'] ?? salary['employee_calling_name']),
          _infoTile(context, "Calling Name", salary['employee_calling_name']),
          _infoTile(context, "Employee No", salary['employee_no']),
          _infoTile(context, "Job Title", salary['job_title']),
          _infoTile(context, "Email", salary['employee_email']),
          _infoTile(context, "Organization", salary['organization_name']),
          _infoTile(
            context,
            "Payroll Month",
            "${_monthName(salary['month'])} ${salary['year'] ?? ''}",
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color titleColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.88 : 1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    final text = (status ?? '-').toString().toUpperCase();
    final color = text == 'FINAL'
        ? Colors.green
        : text == 'DRAFT'
            ? Colors.orange
            : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, dynamic value) {
    final theme = Theme.of(context);
    final text = (value ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.58),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              text.isEmpty ? '-' : text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(BuildContext context, String label, dynamic value) {
    final theme = Theme.of(context);
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;

    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _money(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrongAmountRow(
      BuildContext context, String label, dynamic value) {
    final theme = Theme.of(context);
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            _money(amount),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: AppColors.primary1,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractAllowanceRows(
      Map<String, dynamic> salary) {
    const labels = {
      'allowance_a': 'Allowance A',
      'allowance_b': 'Allowance B',
      'allowance_c': 'Allowance C',
      'allowance_d': 'Allowance D',
      'allowance_e': 'Allowance E',
      'allowance_f': 'Allowance F',
      'allowance_g': 'Allowance G',
      'allowance_h': 'Allowance H',
      'allowance_i': 'Allowance I',
      'allowance_j': 'Allowance J',
      'allowance_k': 'Allowance K',
      'allowance_l': 'Allowance L',
      'allowance_m': 'Allowance M',
      'allowance_n': 'Allowance N',
      'allowance_o': 'Allowance O',
      'allowance_p': 'Allowance P',
      'allowance_q': 'Allowance Q',
      'allowance_r': 'Allowance R',
      'allowance_s': 'Allowance S',
      'allowance_t': 'Allowance T',
    };

    final rows = <Map<String, dynamic>>[];

    labels.forEach((key, label) {
      final value = double.tryParse('${salary[key] ?? 0}') ?? 0;
      if (value > 0) {
        rows.add({'label': label, 'value': salary[key]});
      }
    });

    return rows;
  }

  List<Map<String, dynamic>> _extractDeductionRows(
      Map<String, dynamic> salary) {
    const labels = {
      'deduction_a': 'Deduction A',
      'deduction_b': 'Deduction B',
      'deduction_c': 'Deduction C',
      'deduction_d': 'Deduction D',
      'deduction_e': 'Deduction E',
      'deduction_f': 'Deduction F',
      'deduction_g': 'Deduction G',
      'deduction_h': 'Deduction H',
      'deduction_i': 'Deduction I',
      'deduction_j': 'Deduction J',
      'deduction_k': 'Deduction K',
      'deduction_l': 'Deduction L',
      'deduction_m': 'Deduction M',
      'deduction_n': 'Deduction N',
      'deduction_o': 'Deduction O',
      'deduction_p': 'Deduction P',
      'deduction_q': 'Deduction Q',
      'deduction_r': 'Deduction R',
      'deduction_s': 'Deduction S',
      'deduction_t': 'Deduction T',
    };

    final rows = <Map<String, dynamic>>[];

    labels.forEach((key, label) {
      final value = double.tryParse('${salary[key] ?? 0}') ?? 0;
      if (value > 0) {
        rows.add({'label': label, 'value': salary[key]});
      }
    });

    return rows;
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return "LKR ${amount.toStringAsFixed(2)}";
  }

  String _monthName(dynamic month) {
    final m = int.tryParse(month?.toString() ?? '') ?? 0;
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (m >= 1 && m <= 12) return months[m];
    return '-';
  }
}
