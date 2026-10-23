import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

Widget buildTimeCard(double screenWidth, double screenHeight, String label,
    String time, Color color, String attendance) {
  return Container(
    width: screenWidth * 0.35,
    height: screenHeight * 0.10,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(IconlyBold.time_circle,
                size: screenWidth * 0.04, color: color.withOpacity(0.8)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                ))
          ]),
          const SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
                fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              attendance,
              style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: color == Colors.green ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    ),
  );
}
