import 'dart:math' as math;

import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Four-page, first-install introduction. Uses only Flutter widgets.
/// The existing hasSeenSplash flag is written on Skip / Get Started only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const blue = Color(0xFF1769E8);
  static const ink = Color(0xFF10233F);
  static const muted = Color(0xFF74839A);
  final PageController _controller = PageController();
  late final AnimationController _float;
  int _index = 0;
  bool _busy = false;

  static const _pages = <_OnboardingInfo>[
    _OnboardingInfo(
      title: 'Your Workplace,\nSimplified.',
      description:
          'Everything you need for a better workday,\nall together in Talexa HRMS.',
      pill: 'One Team. One Place.',
      icon: Icons.groups_rounded,
    ),
    _OnboardingInfo(
      title: 'Attendance,\nMade Effortless.',
      description:
          'Check in, check out, and stay on top\nof your daily working hours.',
      pill: 'Every Day Counts',
      icon: Icons.fingerprint_rounded,
    ),
    _OnboardingInfo(
      title: 'Leave Plans,\nMade Simple.',
      description:
          'Request time off, see your balances,\nand track approvals with ease.',
      pill: 'Time for What Matters',
      icon: Icons.calendar_month_rounded,
    ),
    _OnboardingInfo(
      title: 'Your Insights,\nAll in One Place.',
      description:
          'Find HR reports, payroll details,\nand important updates anytime.',
      pill: 'Stay Informed',
      icon: Icons.insert_chart_outlined_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool('hasSeenSplash', true);
      if (!saved) throw StateError('Onboarding state could not be saved');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not continue. Please try again.')),
      );
    }
  }

  void _go(int page) {
    if (_busy || !_controller.hasClients) return;
    if (page < 0 || page >= _pages.length) return;
    HapticFeedback.selectionClick();
    _controller.animateToPage(page,
        duration: const Duration(milliseconds: 430),
        curve: Curves.easeInOutCubic);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _complete();
    } else {
      _go(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final schemeBg = dark ? const Color(0xFF0B1627) : Colors.white;
    final foreground = dark ? Colors.white : ink;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: schemeBg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final short = constraints.maxHeight < 670;
          final artHeight =
              math.min(constraints.maxHeight * (short ? .46 : .51), 440.0);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 20, 7),
              child: Row(children: [
                Expanded(
                    child: Row(
                        children: List.generate(_pages.length, (i) {
                  return Expanded(
                      child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin:
                        EdgeInsets.only(right: i == _pages.length - 1 ? 0 : 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: i <= _index
                          ? blue
                          : (dark ? Colors.white24 : const Color(0xFFDCE8F8)),
                    ),
                  ));
                }))),
                const SizedBox(width: 13),
                TextButton(
                  onPressed: _busy ? null : _complete,
                  child: Text('Skip',
                      style: TextStyle(color: dark ? Colors.white70 : muted)),
                ),
              ]),
            ),
            Expanded(
                child: PageView.builder(
              controller: _controller,
              physics: _busy
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, i) {
                final item = _pages[i];
                return Column(children: [
                  SizedBox(
                    height: artHeight,
                    width: double.infinity,
                    child: _OnboardingArt(
                        page: i, data: item, float: _float, dark: dark),
                  ),
                  Expanded(
                      child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: short ? 29 : 35,
                              height: 1.18,
                              letterSpacing: -1.0,
                              fontWeight: FontWeight.w800,
                              color: foreground,
                            )),
                        const SizedBox(height: 16),
                        Text(item.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: short ? 13 : 14.5,
                                height: 1.55,
                                color: dark ? Colors.white70 : muted)),
                      ]),
                    ),
                  )),
                ]);
              },
            )),
            Padding(
              padding: EdgeInsets.fromLTRB(25, 9, 25, safeBottom + 22),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_index > 0) ...[
                  SizedBox(
                    height: 55,
                    width: 108,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _go(_index - 1),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark ? Colors.white : ink,
                        side: BorderSide(
                            color: dark
                                ? Colors.white30
                                : const Color(0xFFD8E5F6)),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                SizedBox(
                  height: 55,
                  width: _index == 0 ? 205 : 195,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: blue.withOpacity(.22),
                      shape: const StadiumBorder(),
                    ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(
                                    _index == _pages.length - 1
                                        ? 'Get Started'
                                        : 'Next',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const SizedBox(width: 9),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 19),
                              ]),
                  ),
                ),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

class _OnboardingInfo {
  final String title, description, pill;
  final IconData icon;
  const _OnboardingInfo(
      {required this.title,
      required this.description,
      required this.pill,
      required this.icon});
}

class _OnboardingArt extends StatelessWidget {
  final int page;
  final _OnboardingInfo data;
  final Animation<double> float;
  final bool dark;
  const _OnboardingArt(
      {required this.page,
      required this.data,
      required this.float,
      required this.dark});

  static const blue = Color(0xFF1769E8);
  static const navy = Color(0xFF102D60);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final scale = math.min(w / 390, 1.15);
      return ClipRect(
          child: Stack(children: [
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [
                    const Color(0xFF16386B),
                    const Color(0xFF112849),
                    const Color(0xFF0B1627)
                  ]
                : [
                    const Color(0xFFDCEBFF),
                    const Color(0xFFF0F7FF),
                    Colors.white
                  ],
            stops: const [0, .55, 1],
          ),
        ))),
        Positioned.fill(child: CustomPaint(painter: _BackgroundLines(dark))),
        AnimatedBuilder(
            animation: float,
            builder: (context, child) {
              final bob = math.sin(float.value * math.pi * 2) * 5;
              Widget floatAt(double x, double y, Widget widget,
                  {double motion = 1}) {
                return Positioned(
                    left: w * x, top: h * y + bob * motion, child: widget);
              }

              return Stack(children: [
                if (page == 0) ...[
                  floatAt(.15, .18, _avatar('👩🏽‍💼', 82 * scale)),
                  floatAt(.69, .23, _avatar('👨🏻‍💻', 72 * scale),
                      motion: -.7),
                  floatAt(.38, .35, _avatar('👩🏻‍💻', 67 * scale),
                      motion: .65),
                  floatAt(.10, .66, _avatar('👨🏾‍💼', 62 * scale),
                      motion: -.8),
                  floatAt(.72, .66, _avatar('👩🏿‍💼', 68 * scale)),
                  floatAt(
                      .04, .46, _feature(Icons.work_outline_rounded, scale)),
                  floatAt(.82, .46, _feature(Icons.groups_rounded, scale),
                      motion: -.65),
                ] else if (page == 1) ...[
                  floatAt(.14, .24, _feature(Icons.access_time_rounded, scale)),
                  floatAt(.77, .19, _feature(Icons.fingerprint_rounded, scale),
                      motion: -.8),
                  floatAt(
                      .09, .69, _feature(Icons.location_on_outlined, scale)),
                  floatAt(.79, .70, _feature(Icons.task_alt_rounded, scale),
                      motion: -.9),
                  Positioned(
                      left: w * .17,
                      right: w * .17,
                      top: h * .29 + bob,
                      child: _featureCard(
                        scale,
                        icon: Icons.fingerprint_rounded,
                        heading: 'Checked In',
                        subtitle: 'Today • 08:45 AM',
                        extra: 'Your workday has started',
                      )),
                ] else if (page == 2) ...[
                  floatAt(
                      .12, .17, _feature(Icons.beach_access_rounded, scale)),
                  floatAt(
                      .78, .25, _feature(Icons.favorite_border_rounded, scale),
                      motion: -.8),
                  floatAt(.08, .73,
                      _feature(Icons.check_circle_outline_rounded, scale)),
                  Positioned(
                      left: w * .16,
                      right: w * .16,
                      top: h * .24 + bob,
                      child: _calendar(scale)),
                ] else ...[
                  floatAt(
                      .09, .20, _feature(Icons.receipt_long_rounded, scale)),
                  floatAt(.79, .25, _feature(Icons.shield_outlined, scale),
                      motion: -.6),
                  floatAt(.77, .72,
                      _feature(Icons.notifications_active_outlined, scale)),
                  Positioned(
                      left: w * .15,
                      right: w * .15,
                      top: h * .24 + bob,
                      child: _reports(scale)),
                ],
              ]);
            }),
        Positioned(
          left: w * .16,
          right: w * .16,
          bottom: h * .075,
          child: Container(
            height: 54 * scale,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                      color: blue.withOpacity(.12),
                      blurRadius: 22,
                      offset: const Offset(0, 6))
                ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(
                  radius: 15 * scale,
                  backgroundColor: blue,
                  child:
                      Icon(data.icon, color: Colors.white, size: 17 * scale)),
              const SizedBox(width: 10),
              Flexible(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(data.pill,
                          maxLines: 1,
                          style: TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 17 * scale)))),
            ]),
          ),
        ),
      ]));
    });
  }

  Widget _avatar(String emoji, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: navy.withOpacity(.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ]),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size * .54)),
      );

  Widget _feature(IconData icon, double scale) => Container(
        width: 47 * scale,
        height: 43 * scale,
        decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: navy.withOpacity(.17),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ]),
        child: Icon(icon, color: Colors.white, size: 22 * scale),
      );

  Widget _featureCard(double s,
      {required IconData icon,
      required String heading,
      required String subtitle,
      required String extra}) {
    return Container(
      padding: EdgeInsets.all(19 * s),
      decoration: _panelDecoration(),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
            radius: 33 * s,
            backgroundColor: const Color(0xFFE8F1FF),
            child: Icon(icon, size: 37 * s, color: blue)),
        SizedBox(height: 12 * s),
        Text(heading,
            style: TextStyle(
                fontSize: 23 * s, fontWeight: FontWeight.w800, color: navy)),
        SizedBox(height: 6 * s),
        Text(subtitle,
            style: TextStyle(
                color: blue, fontSize: 13 * s, fontWeight: FontWeight.w700)),
        SizedBox(height: 9 * s),
        Text(extra,
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF72829B), fontSize: 11 * s)),
      ]),
    );
  }

  Widget _calendar(double s) => Container(
        padding: EdgeInsets.all(17 * s),
        decoration: _panelDecoration(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Leave Planner',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18 * s,
                    color: navy)),
            Icon(Icons.event_available_rounded, color: blue, size: 24 * s),
          ]),
          SizedBox(height: 14 * s),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Text(d,
                      style: TextStyle(
                          color: const Color(0xFF8795AD), fontSize: 12 * s)))
                  .toList()),
          SizedBox(height: 9 * s),
          for (int row = 0; row < 3; row++)
            Padding(
                padding: EdgeInsets.only(bottom: 7 * s),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final date = row * 7 + i + 1;
                      final selected = date >= 10 && date <= 12;
                      return Container(
                          width: 27 * s,
                          height: 27 * s,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? blue : Colors.transparent),
                          child: Text('$date',
                              style: TextStyle(
                                  fontSize: 11 * s,
                                  color: selected ? Colors.white : navy,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal)));
                    }))),
          SizedBox(height: 4 * s),
          Container(
              padding: EdgeInsets.symmetric(vertical: 9 * s),
              decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, color: blue, size: 16 * s),
                SizedBox(width: 6 * s),
                Text('Leave request submitted',
                    style: TextStyle(
                        color: navy,
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      );

  Widget _reports(double s) => Container(
        padding: EdgeInsets.all(19 * s),
        decoration: _panelDecoration(),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('My Overview',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: navy,
                        fontSize: 18 * s)),
                Icon(Icons.bar_chart_rounded, color: blue, size: 25 * s),
              ]),
              SizedBox(height: 13 * s),
              Text('Monthly activity',
                  style: TextStyle(
                      color: const Color(0xFF74839A), fontSize: 11 * s)),
              SizedBox(height: 10 * s),
              SizedBox(
                  height: 98 * s,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <double>[40, 63, 49, 81, 67, 94]
                          .map((v) => Container(
                              width: 19 * s,
                              height: v * s,
                              decoration: BoxDecoration(
                                  color: v == 94
                                      ? navy
                                      : blue.withOpacity(.23 + (v / 200)),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)))))
                          .toList())),
              SizedBox(height: 17 * s),
              Row(children: [
                Expanded(child: _stat('Attendance', '96%', s)),
                SizedBox(width: 8 * s),
                Expanded(child: _stat('Reports', 'Ready', s)),
              ]),
            ]),
      );

  Widget _stat(String label, String value, double s) => Container(
        padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 8 * s),
        decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: blue, fontWeight: FontWeight.w800, fontSize: 17 * s)),
          Text(label,
              style:
                  TextStyle(color: const Color(0xFF74839A), fontSize: 10 * s)),
        ]),
      );

  BoxDecoration _panelDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: navy.withOpacity(.12),
              blurRadius: 27,
              offset: const Offset(0, 12))
        ],
      );
}

class _BackgroundLines extends CustomPainter {
  final bool dark;
  const _BackgroundLines(this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF86B5F4)).withOpacity(.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final centerY in [.46, .59, .72]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * .5, size.height * centerY),
              width: size.width * 1.14,
              height: size.height * .45),
          paint);
    }
    final sparkle = Paint()
      ..color =
          (dark ? Colors.white : const Color(0xFF77A8F2)).withOpacity(.55);
    for (final v in [
      const Offset(.13, .23),
      const Offset(.88, .35),
      const Offset(.72, .16)
    ]) {
      final x = v.dx * size.width, y = v.dy * size.height;
      final path = Path()
        ..moveTo(x, y - 8)
        ..quadraticBezierTo(x + 2, y - 2, x + 8, y)
        ..quadraticBezierTo(x + 2, y + 2, x, y + 8)
        ..quadraticBezierTo(x - 2, y + 2, x - 8, y)
        ..quadraticBezierTo(x - 2, y - 2, x, y - 8);
      canvas.drawPath(path, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundLines oldDelegate) =>
      oldDelegate.dark != dark;
}
