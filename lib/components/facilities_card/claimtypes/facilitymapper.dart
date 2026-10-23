import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FacilityUIConfig {
  final String title;
  final String subtitle;
  final List<String> bullets;
  final IconData icon;
  final Color color;

  FacilityUIConfig({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.icon,
    required this.color,
  });
}

FacilityUIConfig mapClaimToUI(
  String type,
  double amount,
  int period,
) {
  switch (type) {
    case 'SPECTACLE':
      return FacilityUIConfig(
        title: 'Spectacle Allowance',
        subtitle: 'Spectacle reimbursement facility',
        bullets: [
          'Can be claimed once every $period months',
          'Maximum amount Rs. ${amount.toStringAsFixed(2)}',
        ],
        icon: LucideIcons.glasses,
        color: Colors.blue,
      );

    case 'MEDICAL':
      return FacilityUIConfig(
        title: 'Medical Allowance',
        subtitle: 'Medical reimbursement facility',
        bullets: [
          'Can be claimed once every $period months',
          'Maximum amount Rs. ${amount.toStringAsFixed(2)}',
        ],
        icon: LucideIcons.hospital,
        color: Colors.red,
      );

    default:
      return FacilityUIConfig(
        title: type,
        subtitle: 'Reimbursement facility',
        bullets: [
          'Maximum amount Rs. ${amount.toStringAsFixed(2)}',
        ],
        icon: LucideIcons.fileText,
        color: Colors.green,
      );
  }
}
