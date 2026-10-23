// lib/modules/screens/2FA/screens/twofa_login_verification_screen.dart
// ignore_for_file: depend_on_referenced_packages

import 'dart:ui';
import 'package:corehris/modules/MASTER/2FA/controllers/2fa_login_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TwoFaLoginVerificationScreen extends StatefulWidget {
  const TwoFaLoginVerificationScreen({Key? key}) : super(key: key);

  @override
  State<TwoFaLoginVerificationScreen> createState() =>
      _TwoFaLoginVerificationScreenState();
}

class _TwoFaLoginVerificationScreenState
    extends State<TwoFaLoginVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final TwoFaLoginController c;

  late final AnimationController _pageAnim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // ✅ keep Get.put here, so it won't re-create controller on every build
    c = Get.put(TwoFaLoginController());

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic));

    _pageAnim.forward();
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Two-Factor Verification"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Obx(() {
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    _headerCard(context),

                    const SizedBox(height: 14),

                    _otpCard(context, isDark),

                    const SizedBox(height: 18),

                    // ✅ Verify button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: c.isProcessing.value ? null : c.verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: c.isProcessing.value
                              ? const SizedBox(
                                  key: ValueKey("btnLoader"),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  key: ValueKey("btnText"),
                                  "Verify & Login",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ Smooth loader overlay (blur + fade + scale)
                _loadingOverlay(context),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary2.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.password_outlined, color: AppColors.primary2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Verification Code",
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "A 6-digit code has been sent to your email.",
                  style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      ) ??
                      const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email (read-only)
            TextField(
              controller: c.emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // OTP
            TextField(
              controller: c.otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "OTP Code",
                counterText: "",
                prefixIcon: const Icon(Icons.key_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Tip: Check your inbox & spam folder.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay(BuildContext context) {
    return Obx(() {
      final show = c.isProcessing.value;
      if (!show) return const SizedBox.shrink();

      return Positioned.fill(
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.28)),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Verifying...",
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Please wait",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
