// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:corehris/utils/app_alert.dart';

class SalaryScreenController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> salaryDetails = <String, dynamic>{}.obs;

  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;

  String get selectedMonthLabel {
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
    return months[selectedMonth.value];
  }

  String get employeeId {
    final employeeMap = (salaryDetails['employee'] is Map<String, dynamic>)
        ? salaryDetails['employee'] as Map<String, dynamic>
        : <String, dynamic>{};

    return employeeMap['employee_no']?.toString() ??
        salaryDetails['employee_no']?.toString() ??
        '';
  }

  @override
  void onInit() {
    super.onInit();
    fetchSalary();
  }

  Future<void> fetchSalary() async {
    try {
      isLoading.value = true;

      final y = selectedYear.value.toString();
      final m = selectedMonth.value.toString().padLeft(2, '0');

      // Uses your current API style: getMonthlySalary(year, month)
      final data = await _authService.payroll.getMonthlySalary(y, m);

      if (data == null || data is! Map<String, dynamic>) {
        salaryDetails.clear();
        AppAlert.toast(
          title: 'Salary',
          message: 'No salary records found',
        );
        return;
      }

      salaryDetails.assignAll(data);
    } catch (e) {
      salaryDetails.clear();
      AppAlert.toast(
        title: 'Salary',
        message: 'No salary records found',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openDatePicker(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const months = [
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

    final int currentYear = DateTime.now().year;
    final List<int> years =
        List.generate(8, (index) => currentYear - 4 + index);

    int tempMonth = selectedMonth.value;
    int tempYear = selectedYear.value;

    final FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: tempMonth - 1);

    final FixedExtentScrollController yearController =
        FixedExtentScrollController(
      initialItem: years.indexOf(tempYear) >= 0 ? years.indexOf(tempYear) : 4,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 360,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Month & Year',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: monthController,
                            itemExtent: 46,
                            diameterRatio: 1.15,
                            useMagnifier: true,
                            magnification: 1.08,
                            squeeze: 1.05,
                            selectionOverlay: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.primary1.withOpacity(
                                  isDark ? 0.18 : 0.10,
                                ),
                                border: Border.all(
                                  color: AppColors.primary1.withOpacity(0.18),
                                ),
                              ),
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempMonth = index + 1;
                              });
                            },
                            children: months
                                .map(
                                  (month) => Center(
                                    child: Text(
                                      month,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: yearController,
                            itemExtent: 46,
                            diameterRatio: 1.15,
                            useMagnifier: true,
                            magnification: 1.08,
                            squeeze: 1.05,
                            selectionOverlay: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.primary2.withOpacity(
                                  isDark ? 0.18 : 0.10,
                                ),
                                border: Border.all(
                                  color: AppColors.primary2.withOpacity(0.18),
                                ),
                              ),
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempYear = years[index];
                              });
                            },
                            children: years
                                .map(
                                  (year) => Center(
                                    child: Text(
                                      year.toString(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              selectedMonth.value = tempMonth;
                              selectedYear.value = tempYear;
                              Navigator.pop(context);

                              // clear old data before fetch
                              salaryDetails.clear();
                              fetchSalary();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String formatMoney(dynamic value) {
    if (value == null) return 'LKR 0.00';
    final amount = double.tryParse(value.toString()) ?? 0;
    return 'LKR ${NumberFormat('#,##0.00').format(amount)}';
  }

  Future<void> downloadPayslip() async {
    try {
      if (salaryDetails.isEmpty) {
        AppAlert.toast(
          title: 'No Data',
          message: 'Please load a payslip first.',
        );
        return;
      }

      final emp = _extractEmployeeMap();
      final payroll = _extractPayrollMap();
      final allowances = _extractAllowances();
      final deductions = _extractDeductions();

      if (payroll.isEmpty) {
        AppAlert.toast(
          title: 'No Data',
          message: 'Payroll details not found for selected month.',
        );
        return;
      }

      final bytes = await _buildPayslipPdf(
        emp,
        payroll,
        allowances,
        deductions,
      );

      final safeEmployeeId = employeeId.isNotEmpty ? employeeId : 'employee';

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Payslip_${safeEmployeeId}_${selectedYear.value}_${selectedMonth.value.toString().padLeft(2, '0')}.pdf',
      );
    } catch (e) {
      AppAlert.toast(
        title: 'Payslip',
        message: 'Failed to generate payslip PDF',
      );
    }
  }

  Map<String, dynamic> _extractEmployeeMap() {
    if (salaryDetails['employee'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(salaryDetails['employee']);
    }

    return {
      'employee_fullname': salaryDetails['employee_fullname'] ??
          salaryDetails['full_name'] ??
          salaryDetails['employee_name'] ??
          '-',
      'employee_calling_name': salaryDetails['employee_calling_name'] ??
          salaryDetails['calling_name'] ??
          '-',
      'employee_email':
          salaryDetails['employee_email'] ?? salaryDetails['email'] ?? '-',
      'job_title':
          salaryDetails['job_title'] ?? salaryDetails['designation'] ?? '-',
      'employee_no': salaryDetails['employee_no'] ?? '-',
    };
  }

  Map<String, dynamic> _extractPayrollMap() {
    if (salaryDetails['payroll'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(salaryDetails['payroll']);
    }

    return {
      'basic_salary': salaryDetails['basic_salary'] ?? 0,
      'total_allowances': salaryDetails['total_allowances'] ?? 0,
      'total_deductions': salaryDetails['total_deductions'] ?? 0,
      'gross_pay': salaryDetails['gross_pay'] ?? 0,
      'net_salary':
          salaryDetails['net_salary'] ?? salaryDetails['net_pay'] ?? 0,
    };
  }

  List<Map<String, dynamic>> _extractAllowances() {
    if (salaryDetails['allowances'] is List) {
      return List<Map<String, dynamic>>.from(salaryDetails['allowances']);
    }
    return [];
  }

  List<Map<String, dynamic>> _extractDeductions() {
    if (salaryDetails['deductions'] is List) {
      return List<Map<String, dynamic>>.from(salaryDetails['deductions']);
    }
    return [];
  }

  Future<Uint8List> _buildPayslipPdf(
    Map<String, dynamic> emp,
    Map<String, dynamic> payroll,
    List<Map<String, dynamic>> allowances,
    List<Map<String, dynamic>> deductions,
  ) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0.00');

    String money(dynamic value) {
      if (value == null) return 'LKR -';
      final n = num.tryParse(value.toString());
      return n == null ? 'LKR $value' : 'LKR ${fmt.format(n)}';
    }

    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? '-' : value,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget amountRow(String label, dynamic value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
            pw.Text(
              money(value),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAYSLIP',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$selectedMonthLabel ${selectedYear.value}',
                  style: const pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.blue100),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Employee Details',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                infoRow(
                  'Employee No',
                  emp['employee_no']?.toString() ??
                      salaryDetails['employee_no']?.toString() ??
                      '-',
                ),
                infoRow(
                  'Full Name',
                  emp['employee_fullname']?.toString() ??
                      emp['full_name']?.toString() ??
                      emp['employee_name']?.toString() ??
                      '-',
                ),
                infoRow(
                  'Calling Name',
                  emp['employee_calling_name']?.toString() ??
                      emp['calling_name']?.toString() ??
                      '-',
                ),
                infoRow(
                  'Email',
                  emp['employee_email']?.toString() ??
                      emp['email']?.toString() ??
                      '-',
                ),
                infoRow(
                  'Job Title',
                  emp['job_title']?.toString() ??
                      emp['designation']?.toString() ??
                      '-',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Salary Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                amountRow('Basic Salary', payroll['basic_salary']),
                amountRow('Total Allowances', payroll['total_allowances']),
                amountRow('Total Deductions', payroll['total_deductions']),
                pw.Divider(color: PdfColors.grey300),
                amountRow('Gross Pay', payroll['gross_pay'], bold: true),
                amountRow(
                  'Net Salary',
                  payroll['net_salary'] ?? payroll['net_pay'],
                  bold: true,
                ),
              ],
            ),
          ),
          if (allowances.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Allowances',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green100),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.green50,
              ),
              child: pw.Column(
                children: allowances
                    .map(
                      (item) => amountRow(
                        item['column_name']?.toString() ??
                            item['name']?.toString() ??
                            'Allowance',
                        item['value'],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (deductions.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Deductions',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red100),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.red50,
              ),
              child: pw.Column(
                children: deductions
                    .map(
                      (item) => amountRow(
                        item['column_name']?.toString() ??
                            item['name']?.toString() ??
                            'Deduction',
                        item['value'],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }
}
