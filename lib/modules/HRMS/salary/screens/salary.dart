import 'package:corehris/modules/HRMS/salary/controllers/salary.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Talexa HRMS payslip — grouped, minimal UI matching Settings and Drawer.
/// The existing salary controller, API calls, PDF and date picker are unchanged.
class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  static const _blue = Color(0xFF1769E8);
  static const _navy = Color(0xFF182237);
  static const _muted = Color(0xFF89919D);
  static const _success = Color(0xFF16834B);
  static const _danger = Color(0xFFD64550);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SalaryScreenController>()
        ? Get.find<SalaryScreenController>()
        : Get.put(SalaryScreenController());
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final ink = dark ? Colors.white : _navy;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Payslip', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
            tooltip: 'Download payslip',
            onPressed: controller.isLoading.value || controller.salaryDetails.isEmpty
                ? null : controller.downloadPayslip,
            icon: const Icon(Icons.download_outlined),
          )),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: controller.fetchSalary,
        child: Obx(() {
          final loading = controller.isLoading.value;
          final salary = Map<String, dynamic>.from(controller.salaryDetails);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
            children: [
              _label(context, 'PAYROLL PERIOD'),
              const SizedBox(height: 10),
              _periodSelector(context, controller),
              const SizedBox(height: 24),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(child: CircularProgressIndicator(color: _blue)),
                )
              else if (salary.isEmpty)
                _empty(context)
              else ...[
                _netSalary(context, salary),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: _metric(context, 'Gross pay', salary['gross_pay'], Icons.trending_up_rounded)),
                  const SizedBox(width: 11),
                  Expanded(child: _metric(context, 'Deductions', salary['total_deductions'], Icons.trending_down_rounded)),
                ]),
                const SizedBox(height: 25),
                _label(context, 'EMPLOYEE INFORMATION'),
                const SizedBox(height: 9),
                _group(context, [
                  _detail(context, 'Employee name', salary['employee_fullname'] ?? salary['employee_calling_name']),
                  _detail(context, 'Calling name', salary['employee_calling_name']),
                  _detail(context, 'Employee no.', salary['employee_no']),
                  _detail(context, 'Designation', salary['job_title']),
                  _detail(context, 'Email', salary['employee_email']),
                  _detail(context, 'Organization', salary['organization_name']),
                  _detail(context, 'Payroll month', '${_monthName(salary['month'])} ${salary['year'] ?? ''}'),
                ]),
                const SizedBox(height: 25),
                _label(context, 'EARNINGS'),
                const SizedBox(height: 9),
                _group(context, [
                  _amount(context, 'Basic salary', salary['basic_salary']),
                  _amount(context, 'COLA', salary['cola']),
                  _amount(context, 'Overtime pay', salary['overtime_pay']),
                  _amount(context, 'Salary arrears', salary['salary_arrears']),
                  _amount(context, 'Reimbursement', salary['reimbursement_amount']),
                  _amount(context, 'Leave encashment', salary['leave_encash']),
                  _amount(context, 'Spectacle allowance', salary['spectacle_allowance']),
                  ..._extractAllowanceRows(salary).map((e) => _amount(context, e['label'], e['value'])),
                  _total(context, 'Total allowances', salary['total_allowances']),
                  _total(context, 'Gross pay', salary['gross_pay']),
                  _total(context, 'Total earnings', salary['total_earnings'], highlighted: true),
                ]),
                const SizedBox(height: 25),
                _label(context, 'DEDUCTIONS'),
                const SizedBox(height: 9),
                _group(context, [
                  _amount(context, 'Salary advance', salary['salary_advance']),
                  _amount(context, 'Loan installment', salary['loan_installment']),
                  _amount(context, 'Calculated no pay', salary['calculated_nopay']),
                  _amount(context, 'Per day no pay', salary['per_day_nopay']),
                  _amount(context, 'Intern deduction', salary['intern_deduction']),
                  ..._extractDeductionRows(salary).map((e) => _amount(context, e['label'], e['value'])),
                  _total(context, 'Total deductions', salary['total_deductions'], highlighted: true, color: _danger),
                ]),
                const SizedBox(height: 25),
                _label(context, 'STATUTORY CONTRIBUTIONS'),
                const SizedBox(height: 9),
                _group(context, [
                  _amount(context, 'EPF base', salary['epf_base'], showZero: true),
                  _amount(context, 'Employee EPF 8%', salary['epf_8'], showZero: true),
                  _amount(context, 'Employer EPF 12%', salary['epf_12'], showZero: true),
                  _amount(context, 'ETF 3%', salary['etf_3'], showZero: true),
                  _amount(context, 'EPF employer', salary['epf_employer'], showZero: true),
                ]),
                const SizedBox(height: 28),
                Center(child: Text('Talexa HRMS  •  Salary information',
                  style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : _muted))),
              ],
            ],
          );
        }),
      ),
    );
  }

  Color _ink(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : _navy;
  Color _secondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white60 : _muted;
  Color _surface(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B2638) : Colors.white;
  Color _line(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFECEFF3);

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 3),
    child: Text(text, style: TextStyle(color: _secondary(context), fontSize: 10.5,
      letterSpacing: .9, fontWeight: FontWeight.w600)),
  );

  Widget _periodSelector(BuildContext context, SalaryScreenController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.calendar_month_outlined, color: _blue, size: 22),
        const SizedBox(width: 12),
        Expanded(child: InkWell(
          onTap: () => controller.openDatePicker(context),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
            Expanded(child: Text('${controller.selectedMonthLabel} ${controller.selectedYear.value}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink(context)))),
            Icon(Icons.expand_more_rounded, size: 20, color: _secondary(context)),
          ])),
        )),
        const SizedBox(width: 8),
        SizedBox(height: 40, child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.fetchSalary,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
            elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  Widget _empty(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 32),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
    decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Icon(Icons.receipt_long_outlined, size: 40, color: _blue),
      const SizedBox(height: 16),
      Text('No salary records found', style: TextStyle(color: _ink(context), fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Choose a month and year to view your payslip.', textAlign: TextAlign.center,
        style: TextStyle(color: _secondary(context), height: 1.5, fontSize: 12)),
    ]),
  );

  Widget _netSalary(BuildContext context, Map<String,dynamic> salary) {
    final status = (salary['payroll_status'] ?? '-').toString().toUpperCase();
    final statusColor = status == 'FINAL' ? _success : status == 'DRAFT' ? const Color(0xFFB7791F) : _secondary(context);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(21)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 22, color: _blue),
          const SizedBox(width: 10),
          Expanded(child: Text('Net salary', style: TextStyle(color: _secondary(context), fontSize: 13, fontWeight: FontWeight.w600))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10.5))),
        ]),
        const SizedBox(height: 14),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(_money(salary['net_pay']),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 30, color: _ink(context)))),
        const SizedBox(height: 8),
        Text('${_monthName(salary['month'])} ${salary['year'] ?? ''}',
          style: TextStyle(color: _secondary(context), fontSize: 12)),
      ]),
    );
  }

  Widget _metric(BuildContext context, String label, dynamic amount, IconData icon) => Container(
    constraints: const BoxConstraints(minHeight: 108),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: _blue),
      const SizedBox(height: 9),
      Text(label, style: TextStyle(fontSize: 11, color: _secondary(context))),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(_money(amount), style: TextStyle(fontSize: 15, color: _ink(context), fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _group(BuildContext context, List<Widget> rows) {
    final visible = rows.where((row) => row is! SizedBox).toList();
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(19)),
      child: Column(children: [
        for (var i=0; i<visible.length; i++) ...[
          if (i>0) Divider(height: 1, thickness: 1, color: _line(context)),
          visible[i],
        ],
      ]),
    );
  }

  Widget _detail(BuildContext context, String label, dynamic value) {
    final v = (value ?? '').toString().trim();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Text(label, style: TextStyle(color: _secondary(context), fontSize: 12))),
        const SizedBox(width: 9),
        Expanded(flex: 6, child: Text(v.isEmpty ? '-' : v,
          textAlign: TextAlign.right, style: TextStyle(color: _ink(context), fontSize: 12.5, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  Widget _amount(BuildContext context, String label, dynamic value, {bool showZero=false}) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    if (!showZero && amount <= 0) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: _secondary(context)))),
      const SizedBox(width: 12),
      Text(_money(amount), style: TextStyle(fontSize: 12.5, color: _ink(context), fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _total(BuildContext context, String label, dynamic value, {bool highlighted=false, Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: _ink(context), fontWeight: FontWeight.w700))),
      const SizedBox(width: 12),
      Text(_money(value), style: TextStyle(fontSize: 13, color: highlighted ? (color ?? _blue) : _ink(context),
        fontWeight: FontWeight.w800)),
    ]));
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
