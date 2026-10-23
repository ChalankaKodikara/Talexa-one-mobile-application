import 'package:flutter/material.dart';
import 'package:corehris/theme/theme.dart';

class DashboardSubCardItem extends StatelessWidget {
  final String title;
  final String imgpath;
  final VoidCallback onTap;

  const DashboardSubCardItem({
    super.key,
    required this.title,
    required this.onTap,
    required this.imgpath,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: screenWidth * 0.92,
        height: screenWidth * 0.2,
        child: Card(
          color: AppColors.primary2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: screenWidth * 0.03),
                    Text(
                      'Your',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'View >',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
