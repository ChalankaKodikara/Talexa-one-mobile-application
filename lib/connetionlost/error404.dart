// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Return To home"),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            // If cannot go back, pop the current screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(),
              ),
            );
          },
          child: Icon(Icons.replay_outlined),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.signal_wifi_off, size: 80, color: Colors.grey),
            // SizedBox(height: 16),
            Image.asset(
              "lib/images/error404.png",
              width: 300,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
