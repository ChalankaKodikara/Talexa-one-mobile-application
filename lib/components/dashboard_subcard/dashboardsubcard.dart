import 'package:flutter/material.dart';

class DashboardSubCard extends StatelessWidget {
  final ImageProvider imageUrl;
  final VoidCallback? onTap;

  const DashboardSubCard({
    super.key,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.2,
        height: screenWidth * 0.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(
                image: imageUrl,
                width: 90,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
