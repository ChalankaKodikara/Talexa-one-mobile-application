// // ignore_for_file: depend_on_referenced_packages

// import 'dart:io'; // 🔹 for exit(0)

// import 'package:corehris/modules/screens/main_screens/dashboard/dashboard.dart';
// import 'package:corehris/modules/screens/main_screens/leaves/leavemenu.dart';
// import 'package:corehris/modules/screens/main_screens/noticeboard/screen/notice.dart';
// import 'package:corehris/modules/screens/main_screens/subpages/logout_profile.dart';
// import 'package:corehris/notifications/controller/notification_con.dart';
// import 'package:corehris/widgets/nav_bar/size_config.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import '../../widgets/nav_bar/bottom_nav_btn.dart';

// class FinalViewController extends GetxController {
//   var currentIndex = 0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   }
// }

// class FinalView extends StatefulWidget {
//   const FinalView({super.key});

//   @override
//   State<FinalView> createState() => _FinalViewState();
// }

// class _FinalViewState extends State<FinalView> {
//   final FinalViewController controller = Get.put(FinalViewController());
//   late PageController pageController;

//   DateTime? lastBackPressTime; // 🔹 track double back

//   @override
//   void initState() {
//     super.initState();
//     pageController = PageController(initialPage: 0);

//     Get.put(NotificationController());
//   }

//   void animateToPage(int page) {
//     pageController.jumpToPage(page);
//     controller.currentIndex.value = page;
//   }

//   @override
//   Widget build(BuildContext context) {
//     AppSizes().init(context);

//     final List<Widget> screens = [
//       DashboardScreen(),
//       NoticeScreen(),
//       LeaveMenuScreen(),
//       LogoutProfile(), // Settings page
//     ];

//     return WillPopScope(
//       onWillPop: () async {
//         int index = controller.currentIndex.value;

//         // 🔹 If on Settings, Leave, or Notice → always go back to Dashboard
//         if (index == 3 || index == 2 || index == 1) {
//           animateToPage(0);
//           return false;
//         }

//         // 🔹 If already on Dashboard (0) → handle double back to exit
//         DateTime now = DateTime.now();
//         if (lastBackPressTime == null ||
//             now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
//           lastBackPressTime = now;

//           // Show hint snackbar
//           AppAlert.toast(
//             title: "Exit App",
//             message: "Press back again within 2 sec to fully exit",
//           );

//           return false; // don’t exit yet
//         }

//         // 🔹 Double back within 2 sec → fully exit app
//         exit(0); // ⚡ force close app
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           bottom: false,
//           child: Stack(
//             children: [
//               PageView(
//                 controller: pageController,
//                 onPageChanged: (value) {
//                   controller.currentIndex.value = value;
//                 },
//                 children: screens,
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 left: 0,
//                 child: Obx(() => bottomNav(context)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget bottomNav(BuildContext context) {
//     return Material(
//       elevation: 6,
//       child: Container(
//         height: AppSizes.blockSizeHorizontal * 16,
//         width: MediaQuery.of(context).size.width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             BottomNavBTN(
//               onPressed: (val) => animateToPage(val),
//               currentIndex: controller.currentIndex.value,
//               index: 0,
//               icon: LucideIcons.layoutDashboard,
//             ),
//             BottomNavBTN(
//               onPressed: (val) => animateToPage(val),
//               currentIndex: controller.currentIndex.value,
//               index: 1,
//               icon: LucideIcons.calendarDays,
//             ),
//             BottomNavBTN(
//               onPressed: (val) => animateToPage(val),
//               currentIndex: controller.currentIndex.value,
//               index: 2,
//               icon: LucideIcons.umbrella,
//             ),
//             BottomNavBTN(
//               onPressed: (val) => animateToPage(val),
//               currentIndex: controller.currentIndex.value,
//               index: 3,
//               icon: LucideIcons.settings,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
