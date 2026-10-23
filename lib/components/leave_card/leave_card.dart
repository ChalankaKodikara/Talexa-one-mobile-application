/* ======================= LEAVE CARD ======================= */

import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final String name;
  final String available;
  final String total;

  const LeaveCard({
    required this.name,
    required this.available,
    required this.total,
    super.key,
  });

  /// Predefined color palette
  static final List<Color> _colorPalette = [
    AppColors.primary2,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
  ];

  /// Stable color generator
  Color _getStableColor(String name) {
    final hash = name.hashCode;
    final index = hash % _colorPalette.length;
    return _colorPalette[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stableColor = _getStableColor(name);

    final textColor = theme.colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.65);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final countSize = constraints.maxHeight < 118 ? 28.0 : 32.0;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: stableColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total Leaves",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        total,
                        style: TextStyle(
                          fontSize: countSize,
                          fontWeight: FontWeight.w800,
                          color: stableColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Available: $available",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
