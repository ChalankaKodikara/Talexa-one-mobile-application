import 'package:flutter/material.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/resetpassword.dart';
import 'package:corehris/widgets/nav_bar/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreeen extends StatefulWidget {
  const MainScreeen({super.key});

  @override
  State<MainScreeen> createState() => _MainScreeenState();
}

class _MainScreeenState extends State<MainScreeen> {
  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUsername(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final username = snapshot.data ?? '';
          List<Widget> screens = [
            DashboardScreen(),
            AttendancePage(
              username: username,
            ),
            LeaveMenuScreen(),
            ResetpasswordPage(username: username),
          ];
          return Scaffold(
            body: IndexedStack(
              index: 0, // Change this index to switch between screens
              children: screens,
            ),
          );
        }
      },
    );
  }
}

double animatedPositionedLeftValue(int currentIndex) {
  switch (currentIndex) {
    case 0:
      return AppSizes.blockSizeHorizontal * 5.5;
    case 1:
      return AppSizes.blockSizeHorizontal * 22.5;
    case 2:
      return AppSizes.blockSizeHorizontal * 39.5;
    case 3:
      return AppSizes.blockSizeHorizontal * 56.5;
    case 4:
      return AppSizes.blockSizeHorizontal * 73.5;
    default:
      return 0;
  }
}

final List<Color> gradient = [
  Colors.purple.withOpacity(0.8),
  Colors.purple.withOpacity(0.5),
  Colors.transparent,
];
