// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class UpdateCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final ImageProvider image;

  const UpdateCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the background color and text color based on the status
    Color statusBackgroundColor;
    Color statusTextColor;

    switch (status) {
      case 'Pending':
        statusBackgroundColor = Colors.orange;
        statusTextColor = Colors.white;
        break;
      case 'NOT APPROVED':
        statusBackgroundColor = Colors.orange;
        statusTextColor = Colors.white;
        break;
      case 'APPROVED':
        statusBackgroundColor = Colors.green;
        statusTextColor = Colors.white;
        break;
      case 'Approved':
        statusBackgroundColor = Colors.green;
        statusTextColor = Colors.white;
        break;
      case 'Rejected':
        statusBackgroundColor = Colors.red;
        statusTextColor = Colors.white;
        break;
      default:
        statusBackgroundColor = Colors.grey;
        statusTextColor = Colors.white;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image(image: image, width: 20, height: 20),
                      const SizedBox(width: 8.0),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),

            // Status Container
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: statusBackgroundColor,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 9.0,
                  color: statusTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
