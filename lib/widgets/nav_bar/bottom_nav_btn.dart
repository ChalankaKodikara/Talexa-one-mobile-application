// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:corehris/widgets/nav_bar/size_config.dart';

class BottomNavBTN extends StatelessWidget {
  final Function(int) onPressed;
  final int index;
  final int currentIndex;
  final IconData icon;

  const BottomNavBTN({
    super.key,
    required this.onPressed,
    required this.index,
    required this.currentIndex,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes().init(context);
    final bool isActive = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () => onPressed(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        height: AppSizes.blockSizeHorizontal * 13,
        width: AppSizes.blockSizeHorizontal * 17,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: isActive ? const Color(0xFF2495FE) : Colors.grey.shade500,
        ),
      ),
    );
  }
}
