// // // ignore_for_file: library_private_types_in_public_api, avoid_print

// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hexcolor/hexcolor.dart';
// // import 'package:corehris/auth/authservices.dart';
// // import 'package:corehris/components/leavedata.dart';
// // import 'package:dio/dio.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // class BuildBarChart extends StatefulWidget {
// //   const BuildBarChart({super.key});

// //   @override
// //   _BuildBarChartState createState() => _BuildBarChartState();
// // }

// // class _BuildBarChartState extends State<BuildBarChart> {
// //   Future<LeaveData>? futureLeaveData;
// //   final AuthService _authService = AuthService(dio: Dio());
// //   late String employeeId = '';

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadEmployeeId();
// //   }

// //   Future<void> _loadEmployeeId() async {
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     if (!mounted) return;
// //     setState(() {
// //       employeeId = prefs.getString('employee_no') ?? '';
// //       if (employeeId.isNotEmpty) {
// //         futureLeaveData = _authService.countLeaveData(employeeId);
// //       } else {
// //         print('Error: employeeId is not set in Shared Preferences');
// //       }
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return FutureBuilder<LeaveData>(
// //       future: futureLeaveData,
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         } else if (snapshot.hasError) {
// //           return Center(child: Text('Error: ${snapshot.error}'));
// //         } else if (snapshot.hasData) {
// //           return BarChart(
// //             BarChartData(
// //               barTouchData: barTouchData,
// //               titlesData: titlesData,
// //               borderData: borderData,
// //               barGroups: barGroups(snapshot.data!),
// //               gridData: const FlGridData(show: false),
// //               alignment: BarChartAlignment.center,
// //               maxY: 20,
// //               groupsSpace: 23,
// //             ),
// //           );
// //         } else {
// //           return const Center(child: Text('No data available'));
// //         }
// //       },
// //     );
// //   }

// //   BarTouchData get barTouchData => BarTouchData(
// //         enabled: false,
// //         touchTooltipData: BarTouchTooltipData(
// //           getTooltipColor: (group) => Colors.transparent,
// //           tooltipPadding: EdgeInsets.zero,
// //           tooltipMargin: 2,
// //           getTooltipItem: (
// //             BarChartGroupData group,
// //             int groupIndex,
// //             BarChartRodData rod,
// //             int rodIndex,
// //           ) {
// //             return BarTooltipItem(
// //               rod.toY.round().toString(),
// //               const TextStyle(
// //                 color: Colors.black38,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             );
// //           },
// //         ),
// //       );

// //   Widget getTitles(double value, TitleMeta meta) {
// //     const style = TextStyle(
// //       color: Colors.black38,
// //       fontWeight: FontWeight.bold,
// //       fontSize: 14,
// //     );
// //     String text;
// //     switch (value.toInt()) {
// //       case 0:
// //         text = 'Annual';
// //         break;
// //       case 1:
// //         text = 'Casual';
// //         break;
// //       case 2:
// //         text = 'Special';
// //         break;
// //       case 3:
// //         text = 'Medical';
// //         break;
// //       case 4:
// //         text = 'No Pay';
// //         break;
// //       default:
// //         text = '';
// //         break;
// //     }
// //     return SideTitleWidget(
// //       axisSide: meta.axisSide,
// //       space: 3,
// //       child: Text(text, style: style),
// //     );
// //   }

// //   FlTitlesData get titlesData => FlTitlesData(
// //         show: true,
// //         bottomTitles: AxisTitles(
// //           sideTitles: SideTitles(
// //             showTitles: true,
// //             reservedSize: 50,
// //             getTitlesWidget: getTitles,
// //           ),
// //         ),
// //         leftTitles: const AxisTitles(
// //           sideTitles: SideTitles(showTitles: false),
// //         ),
// //         topTitles: const AxisTitles(
// //           sideTitles: SideTitles(showTitles: false),
// //         ),
// //         rightTitles: const AxisTitles(
// //           sideTitles: SideTitles(showTitles: false),
// //         ),
// //       );

// //   FlBorderData get borderData => FlBorderData(
// //         show: false,
// //       );

// //   List<BarChartGroupData> barGroups(LeaveData leaveData) {
// //     return [
// //       BarChartGroupData(
// //         x: 0,
// //         barRods: [
// //           BarChartRodData(
// //             toY: leaveData.actualLeave.annualLeaveCount,
// //             width: 50,
// //             color: HexColor('#F0EAFF'),
// //           )
// //         ],
// //         showingTooltipIndicators: [0],
// //       ),
// //       BarChartGroupData(
// //         x: 1,
// //         barRods: [
// //           BarChartRodData(
// //             toY: leaveData.actualLeave.casualLeaveCount,
// //             width: 50,
// //             color: HexColor('#B5FFBE'),
// //           )
// //         ],
// //         showingTooltipIndicators: [0],
// //       ),
// //       BarChartGroupData(
// //         x: 2,
// //         barRods: [
// //           BarChartRodData(
// //             toY: leaveData.actualLeave.specialLeaveCount,
// //             width: 50,
// //             color: HexColor('#FFC9B7'),
// //           )
// //         ],
// //         showingTooltipIndicators: [0],
// //       ),
// //       BarChartGroupData(
// //         x: 3,
// //         barRods: [
// //           BarChartRodData(
// //             toY: leaveData.actualLeave.medicalLeaveCount,
// //             width: 50,
// //             color: HexColor('#FFBDE8'),
// //           )
// //         ],
// //         showingTooltipIndicators: [0],
// //       ),
// //       BarChartGroupData(
// //         x: 4,
// //         barRods: [
// //           BarChartRodData(
// //             toY: leaveData.actualLeave.medicalLeaveCount,
// //             width: 50,
// //             color: HexColor('#BE8D00'),
// //           )
// //         ],
// //         showingTooltipIndicators: [0],
// //       ),
// //     ];
// //   }
// // }

// // This is a Flutter demo to showcase a bar chart using FL Chart package
// // without relying on actual API calls or data fetching.
// // Instead, it uses a mock dataset to simulate the leave data.

// import 'package:corehris/theme/theme.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class BuildBarChart extends StatelessWidget {
//   final MockLeaveData mockLeaveData;
//   const BuildBarChart({required this.mockLeaveData, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BarChart(
//       BarChartData(
//         barTouchData: barTouchData,
//         titlesData: titlesData,
//         borderData: borderData,
//         barGroups: barGroups(mockLeaveData),
//         gridData: const FlGridData(show: false),
//         alignment: BarChartAlignment.center,
//         maxY: 14,
//         groupsSpace: 25,
//       ),
//     );
//   }

//   BarTouchData get barTouchData => BarTouchData(
//         enabled: false,
//         touchTooltipData: BarTouchTooltipData(
//           getTooltipColor: (group) => Colors.transparent,
//           tooltipPadding: EdgeInsets.zero,
//           tooltipMargin: 2,
//           getTooltipItem: (
//             BarChartGroupData group,
//             int groupIndex,
//             BarChartRodData rod,
//             int rodIndex,
//           ) {
//             return BarTooltipItem(
//               rod.toY.round().toString(),
//               const TextStyle(
//                 color: Colors.black38,
//                 fontWeight: FontWeight.bold,
//               ),
//             );
//           },
//         ),
//       );

//   Widget getTitles(double value, TitleMeta meta) {
//     const style = TextStyle(
//       color: Colors.black38,
//       fontWeight: FontWeight.bold,
//       fontSize: 14,
//     );
//     String text;
//     switch (value.toInt()) {
//       case 0:
//         text = 'Annual';
//         break;
//       case 1:
//         text = 'Casual';
//         break;
//       case 2:
//         text = 'Special';
//         break;
//       case 3:
//         text = 'Medical';
//         break;
//       case 4:
//         text = 'No Pay';
//         break;
//       default:
//         text = '';
//         break;
//     }
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 2,
//       child: Text(text, style: style),
//     );
//   }

//   FlTitlesData get titlesData => FlTitlesData(
//         show: true,
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 20,
//             getTitlesWidget: getTitles,
//           ),
//         ),
//         leftTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//       );

//   FlBorderData get borderData => FlBorderData(show: false);

//   List<BarChartGroupData> barGroups(MockLeaveData leaveData) {
//     return [
//       BarChartGroupData(
//         x: 0,
//         barRods: [
//           BarChartRodData(
//             toY: leaveData.actualLeave.annualLeaveCount,
//             width: 50,
//             color: AppColors.bar1,
//           )
//         ],
//         showingTooltipIndicators: [0],
//       ),
//       BarChartGroupData(
//         x: 1,
//         barRods: [
//           BarChartRodData(
//             toY: leaveData.actualLeave.casualLeaveCount,
//             width: 50,
//             color: AppColors.bar2,
//           )
//         ],
//         showingTooltipIndicators: [0],
//       ),
//       BarChartGroupData(
//         x: 2,
//         barRods: [
//           BarChartRodData(
//             toY: leaveData.actualLeave.specialLeaveCount,
//             width: 50,
//             color: AppColors.bar3,
//           )
//         ],
//         showingTooltipIndicators: [0],
//       ),
//       BarChartGroupData(
//         x: 3,
//         barRods: [
//           BarChartRodData(
//             toY: leaveData.actualLeave.medicalLeaveCount,
//             width: 50,
//             color: AppColors.bar4,
//           )
//         ],
//         showingTooltipIndicators: [0],
//       ),
//       BarChartGroupData(
//         x: 4,
//         barRods: [
//           BarChartRodData(
//             toY: leaveData.actualLeave.noPayLeaveCount,
//             width: 50,
//             color: AppColors.bar5,
//           )
//         ],
//         showingTooltipIndicators: [0],
//       ),
//     ];
//   }
// }

// // Mock data classes to simulate LeaveData structure
// class MockLeaveData {
//   final ActualLeave actualLeave;
//   MockLeaveData({required this.actualLeave});
// }

// class ActualLeave {
//   final double annualLeaveCount;
//   final double casualLeaveCount;
//   final double specialLeaveCount;
//   final double medicalLeaveCount;
//   final double noPayLeaveCount;

//   ActualLeave({
//     required this.annualLeaveCount,
//     required this.casualLeaveCount,
//     required this.specialLeaveCount,
//     required this.medicalLeaveCount,
//     required this.noPayLeaveCount,
//   });
// }
