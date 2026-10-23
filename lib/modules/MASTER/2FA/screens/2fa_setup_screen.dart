import 'package:corehris/modules/MASTER/2FA/controllers/2fa_con.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TwoFaSetupScreen extends StatefulWidget {
  const TwoFaSetupScreen({super.key});

  @override
  State<TwoFaSetupScreen> createState() => _TwoFaSetupScreenState();
}

class _TwoFaSetupScreenState extends State<TwoFaSetupScreen> {
  static const blue = Color(0xFF1769E8);
  late final TwoFaController c;
  final FocusNode otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<TwoFaController>()
        ? Get.find<TwoFaController>()
        : Get.put(TwoFaController());
  }

  @override
  void dispose() {
    otpFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF89919D);
    final divider = dark ? Colors.white12 : const Color(0xFFECEFF3);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final busy = c.isProcessing.value;
          final enabled = c.isEnabled.value;
          final settingUp = c.isSettingUp.value;
          return RefreshIndicator(
            onRefresh: c.refreshStatus,
            color: blue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                const SizedBox(height: 12),
                const Center(child: Icon(Icons.verified_user_outlined, size: 42, color: blue)),
                const SizedBox(height: 18),
                Text('Protect your account', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 8),
                Text('Add an extra layer of security to your Talexa workspace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5, color: muted)),
                const SizedBox(height: 34),
                _label('SECURITY SETTINGS', muted),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(19)),
                  child: Row(children: [
                    Icon(Icons.shield_outlined, size: 23, color: ink),
                    const SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email verification', style: TextStyle(color: ink,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(enabled ? 'Two-factor authentication is enabled'
                            : settingUp ? 'Complete verification to enable'
                            : 'Require an email code at sign-in',
                          style: TextStyle(color: muted, fontSize: 11.5, height: 1.4)),
                      ],
                    )),
                    Switch.adaptive(
                      value: enabled,
                      onChanged: busy || settingUp ? null : c.toggleSwitch,
                      activeTrackColor: blue,
                      activeColor: Colors.white,
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Icon(enabled ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      size: 21, color: enabled ? const Color(0xFF16A36A) : blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(enabled
                        ? 'Your account has additional sign-in protection.'
                        : settingUp ? 'Enter the email verification code below to finish setup.'
                        : 'Turn this on to verify new sign-ins with a one-time code.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.45))),
                  ]),
                ),
                if (busy && !settingUp) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator(color: blue, strokeWidth: 2.4)),
                ],
                if (settingUp) ...[
                  const SizedBox(height: 30),
                  _label('VERIFY YOUR EMAIL', muted),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(17, 21, 17, 18),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(19)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Enter verification code', style: TextStyle(color: ink,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Enter the six-digit code sent to your registered email.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: muted)),
                      const SizedBox(height: 22),
                      _SixDigitCode(controller: c.otpController, focusNode: otpFocus,
                          dark: dark, divider: divider, ink: ink),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: busy ? null : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            c.confirmEnable();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: blue,
                            foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: busy ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify & Enable',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Center(child: TextButton(
                        onPressed: busy ? null : c.cancelSetup,
                        child: Text('Cancel setup', style: TextStyle(color: muted)),
                      )),
                    ]),
                  ),
                ],
                const SizedBox(height: 25),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_outline, size: 15, color: muted),
                  const SizedBox(width: 7),
                  Flexible(child: Text('Keep your verification codes private.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: muted))),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
          letterSpacing: .9, color: color));
}

class _SixDigitCode extends StatelessWidget {
  const _SixDigitCode({required this.controller, required this.focusNode,
    required this.dark, required this.divider, required this.ink});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool dark;
  final Color divider;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: controller, builder: (context, _) {
      final code = controller.text;
      return SizedBox(height: 56, child: Stack(children: [
        Positioned.fill(child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6)],
          showCursor: false,
          enableInteractiveSelection: false,
          style: const TextStyle(color: Colors.transparent, fontSize: 22),
          decoration: const InputDecoration(counterText: '', filled: false,
            border: InputBorder.none, enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none),
        )),
        IgnorePointer(child: Row(children: List.generate(6, (i) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF263449) : const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: i < code.length
                  ? const Color(0xFF1769E8) : divider),
            ),
            child: Text(i < code.length ? code[i] : '',
              style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        )))),
      ]));
    });
  }
}
