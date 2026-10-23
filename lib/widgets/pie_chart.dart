// import 'package:corehris/model/levedatareport.dart';
// import 'package:corehris/theme/theme.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:corehris/auth/authservices.dart';
// import 'package:corehris/components/leavedata.dart';
// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PieChartSample2 extends StatefulWidget {
//   const PieChartSample2({super.key});

//   @override
//   State<StatefulWidget> createState() => _PieChartSample2State();
// }

// class _PieChartSample2State extends State<PieChartSample2> {
//   int touchedIndex = -1;
//   Future<LeaveData>? futureLeaveData;
//   final AuthService _authService = AuthService(dio: Dio());
//   late String employeeId = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadEmployeeId();
//   }

//   Future<void> _loadEmployeeId() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     if (!mounted) return;
//     setState(() {
//       employeeId = prefs.getString('employee_no') ?? '';
//       if (employeeId.isNotEmpty) {
//         futureLeaveData = _authService.countLeaveData(employeeId);
//       } else {
//         print('Error: employeeId is not set in Shared Preferences');
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get screen width for responsive scaling
//     double screenWidth = MediaQuery.of(context).size.width;

//     return FutureBuilder<LeaveData>(
//       future: futureLeaveData,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (snapshot.hasData) {
//           return AspectRatio(
//             aspectRatio: 1.3,
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: AspectRatio(
//                     aspectRatio: 1,
//                     child: PieChart(
//                       PieChartData(
//                         pieTouchData: PieTouchData(
//                           touchCallback:
//                               (FlTouchEvent event, pieTouchResponse) {
//                             setState(() {
//                               if (!event.isInterestedForInteractions ||
//                                   pieTouchResponse == null ||
//                                   pieTouchResponse.touchedSection == null) {
//                                 touchedIndex = -1;
//                                 return;
//                               }
//                               touchedIndex = pieTouchResponse
//                                   .touchedSection!.touchedSectionIndex;
//                             });
//                           },
//                         ),
//                         borderData: FlBorderData(show: false),
//                         sectionsSpace: 0,
//                         centerSpaceRadius: screenWidth * 0.1,
//                         sections: showingSections(snapshot.data!, screenWidth),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: screenWidth * 0.07),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     buildIndicator(getSectionColor(0), 'Annual', screenWidth),
//                     SizedBox(height: screenWidth * 0.01),
//                     buildIndicator(getSectionColor(1), 'Casual', screenWidth),
//                     SizedBox(height: screenWidth * 0.01),
//                     buildIndicator(getSectionColor(2), 'Special', screenWidth),
//                     SizedBox(height: screenWidth * 0.01),
//                     buildIndicator(getSectionColor(3), 'Medical', screenWidth),
//                     SizedBox(height: screenWidth * 0.01),
//                     buildIndicator(getSectionColor(4), 'NoPay', screenWidth),
//                     SizedBox(height: screenWidth * 0.05),
//                   ],
//                 ),
//                 SizedBox(width: screenWidth * 0.07),
//               ],
//             ),
//           );
//         } else {
//           return const Center(child: Text('No data available'));
//         }
//       },
//     );
//   }

//   List<PieChartSectionData> showingSections(
//       LeaveData leaveData, double screenWidth) {
//     return List.generate(5, (i) {
//       final isTouched = i == touchedIndex;
//       final fontSize = isTouched ? screenWidth * 0.06 : screenWidth * 0.04;
//       final radius = isTouched ? screenWidth * 0.15 : screenWidth * 0.125;
//       const shadows = [
//         Shadow(
//           color: Colors.black26,
//           blurRadius: 8,
//           offset: Offset(2, 2),
//         )
//       ];
//       return PieChartSectionData(
//         color: getSectionColor(i),
//         value: getLeaveValue(leaveData, i),
//         title: getLeaveValue(leaveData, i).toString(),
//         radius: radius,
//         titleStyle: TextStyle(
//           fontSize: fontSize,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//           shadows: shadows,
//         ),
//       );
//     });
//   }

//   Widget buildIndicator(Color color, String text, double screenWidth) {
//     return Row(
//       children: <Widget>[
//         Container(
//           width: screenWidth * 0.04,
//           height: screenWidth * 0.04,
//           decoration: BoxDecoration(
//             shape: BoxShape.rectangle,
//             color: color,
//           ),
//         ),
//         SizedBox(width: screenWidth * 0.02),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: screenWidth * 0.04,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ],
//     );
//   }

//   Color getSectionColor(int index) {
//     switch (index) {
//       case 0:
//         return AppColors.primary2; // Annual Leave
//       case 1:
//         return AppColors.primary2; // Casual Leave
//       case 2:
//         return AppColors.primary3; // Special Leave
//       case 3:
//         return AppColors.primary4; // Medical Leave
//       case 4:
//         return AppColors.primary5; // Nopay Leave
//       default:
//         return Colors.grey; // Default color for any unexpected index
//     }
//   }

//   double getLeaveValue(LeaveData leaveData, int index) {
//     switch (index) {
//       case 0:
//         return leaveData.actualLeave.annualLeaveCount;
//       case 1:
//         return leaveData.actualLeave.casualLeaveCount;
//       case 2:
//         return leaveData.actualLeave.specialLeaveCount;
//       case 3:
//         return leaveData.actualLeave.medicalLeaveCount;
//       case 4:
//         return leaveData.currentLeave.noPayLeaveCount;
//       default:
//         return 0;
//     }
//   }
// }
