import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:get/get.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/Dashboard', page: () => DashboardScreen()),
  ];
}
