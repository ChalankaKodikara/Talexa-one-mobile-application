import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiveMiniClock extends StatefulWidget {
  final double size;
  final Color ringColor;
  final Color handColor;
  final Color dotColor;
  final Color tickColor;
  final Color faceColor;

  const LiveMiniClock({
    super.key,
    this.size = 42,
    this.ringColor = const Color(0x66FFFFFF),
    this.handColor = Colors.white,
    this.dotColor = Colors.white,
    this.tickColor = const Color(0x99FFFFFF),
    this.faceColor = Colors.transparent,
  });

  @override
  State<LiveMiniClock> createState() => _LiveMiniClockState();
}

class _LiveMiniClockState extends State<LiveMiniClock> {
  late Timer _timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _MiniClockPainter(
          now: now,
          ringColor: widget.ringColor,
          handColor: widget.handColor,
          dotColor: widget.dotColor,
          tickColor: widget.tickColor,
          faceColor: widget.faceColor,
        ),
      ),
    );
  }
}

class _MiniClockPainter extends CustomPainter {
  final DateTime now;
  final Color ringColor;
  final Color handColor;
  final Color dotColor;
  final Color tickColor;
  final Color faceColor;

  _MiniClockPainter({
    required this.now,
    required this.ringColor,
    required this.handColor,
    required this.dotColor,
    required this.tickColor,
    required this.faceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final handPaint = Paint()
      ..color = handColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = dotColor;

    canvas.drawCircle(center, radius - 1, facePaint);
    canvas.drawCircle(center, radius - 1, ringPaint);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 4),
        center.dy + math.sin(angle) * (radius - 4),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 7),
        center.dy + math.sin(angle) * (radius - 7),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final hour = now.hour % 12;
    final minute = now.minute;
    final second = now.second;

    final hourAngle = ((hour + minute / 60) * 30 - 90) * math.pi / 180;
    final minuteAngle = ((minute + second / 60) * 6 - 90) * math.pi / 180;
    final secondAngle = (second * 6 - 90) * math.pi / 180;

    handPaint.strokeWidth = 2.2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAngle) * (radius * 0.42),
        center.dy + math.sin(hourAngle) * (radius * 0.42),
      ),
      handPaint,
    );

    handPaint.strokeWidth = 1.6;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minuteAngle) * (radius * 0.58),
        center.dy + math.sin(minuteAngle) * (radius * 0.58),
      ),
      handPaint,
    );

    final secondPaint = Paint()
      ..color = handColor.withOpacity(0.75)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(secondAngle) * (radius * 0.65),
        center.dy + math.sin(secondAngle) * (radius * 0.65),
      ),
      secondPaint,
    );

    canvas.drawCircle(center, 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniClockPainter oldDelegate) {
    return oldDelegate.now.second != now.second;
  }
}
