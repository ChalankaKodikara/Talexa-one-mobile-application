import 'package:corehris/modules/MASTER/2FA/controllers/2fa_login_con.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TwoFaLoginVerificationScreen extends StatefulWidget {
  const TwoFaLoginVerificationScreen({super.key});

  @override
  State<TwoFaLoginVerificationScreen> createState() =>
      _TwoFaLoginVerificationScreenState();
}

class _TwoFaLoginVerificationScreenState extends State<TwoFaLoginVerificationScreen> {
  static const blue = Color(0xFF1769E8);
  late final TwoFaLoginController c;
  final otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<TwoFaLoginController>()
        ? Get.find<TwoFaLoginController>() : Get.put(TwoFaLoginController());
  }

  @override
  void dispose() {
    otpFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF89919D);
    final line = dark ? Colors.white12 : const Color(0xFFECEFF3);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Verify Login', style: TextStyle(fontSize: 17,
          fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(top: false, child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
        child: Column(children: [
          const SizedBox(height: 12),
          const Icon(Icons.mark_email_read_outlined, color: blue, size: 44),
          const SizedBox(height: 20),
          Text('Verify it’s you', style: TextStyle(fontSize: 25,
            fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 10),
          Text('Enter the six-digit verification code sent to your email address.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: muted)),
          const SizedBox(height: 12),
          AnimatedBuilder(animation: c.emailController, builder: (context, _) =>
            Text(c.emailController.text, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: blue))),
          const SizedBox(height: 34),
          Align(alignment: Alignment.centerLeft,
            child: Text('VERIFICATION CODE', style: TextStyle(color: muted,
              fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: .9))),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 23, 16, 22),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(19)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Enter OTP', style: TextStyle(color: ink, fontSize: 14,
                fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Use the latest code received in your inbox.',
                style: TextStyle(fontSize: 12, height: 1.4, color: muted)),
              const SizedBox(height: 22),
              AnimatedBuilder(animation: c.otpController, builder: (context, _) {
                final otp = c.otpController.text;
                return SizedBox(height: 56, child: Stack(children: [
                  Positioned.fill(child: TextField(
                    controller: c.otpController,
                    focusNode: otpFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6)],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(color: Colors.transparent, fontSize: 22),
                    decoration: const InputDecoration(counterText: '', filled: false,
                      border: InputBorder.none, enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none),
                    onSubmitted: (_) { if (!c.isProcessing.value) c.verifyOtp(); },
                  )),
                  IgnorePointer(child: Row(children: List.generate(6, (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF263449) : const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: i < otp.length ? blue : line),
                      ),
                      child: Text(i < otp.length ? otp[i] : '',
                        style: TextStyle(color: ink, fontSize: 20,
                          fontWeight: FontWeight.w700)),
                    ),
                  )))),
                ]));
              }),
              const SizedBox(height: 25),
              Obx(() => SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: c.isProcessing.value ? null : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    c.verifyOtp();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: blue,
                    foregroundColor: Colors.white, elevation: 0,
                    disabledBackgroundColor: blue.withOpacity(.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: c.isProcessing.value
                      ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Continue',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              )),
            ]),
          ),
          const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline_rounded, size: 16, color: muted),
            const SizedBox(width: 8),
            Flexible(child: Text('Secure verification for your account',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted))),
          ]),
        ]),
      )),
    );
  }
}
