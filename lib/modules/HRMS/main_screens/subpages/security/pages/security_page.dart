import 'package:corehris/modules/MASTER/2FA/screens/2fa_setup_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/resetpassword.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/controllers/security_con.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/pinsetup_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  static const _blue = Color(0xFF1769E8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SecurityController>()
        ? Get.find<SecurityController>()
        : Get.put(SecurityController());
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF8B9099);
    final line = dark ? Colors.white12 : const Color(0xFFECEFF3);

    Widget section(String title, List<Widget> tiles) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 0, 9),
          child: Text(title.toUpperCase(), style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: .55, color: muted,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i != 0) Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(height: 1, thickness: 1, color: line),
              ),
              tiles[i],
            ],
          ]),
        ),
      ]),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ink,
        title: const Text('Privacy & Security', style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700,
        )),
      ),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 28),
        children: [
          Text('Protect your account', style: TextStyle(
            fontSize: 23, fontWeight: FontWeight.w700, color: ink,
          )),
          const SizedBox(height: 6),
          Text('Manage how you securely access Talexa HRMS.',
            style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          section('Login security', [
            _SecurityRow(
              icon: Icons.pin_outlined, title: 'Set Up PIN',
              subtitle: 'Create or change your 4-digit PIN', dark: dark,
              onTap: () => Get.to(() => PinSetupPage(username: controller.username.value)),
            ),
            Obx(() {
              final enabled = controller.isBiometricEnabled.value;
              final supported = controller.canUseBiometrics.value;
              return _SecurityRow(
                icon: controller.availableBiometrics.any((b) => b.toString().contains('face'))
                    ? Icons.face_outlined : Icons.fingerprint_rounded,
                title: 'Biometric Login',
                subtitle: supported
                    ? 'Use your device biometrics to sign in'
                    : 'Not available on this device',
                dark: dark,
                trailing: Switch.adaptive(
                  value: enabled && supported,
                  activeTrackColor: _blue,
                  onChanged: supported ? controller.toggleBiometric : null,
                ),
              );
            }),
            _SecurityRow(
              icon: Icons.phonelink_lock_outlined,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of verification', dark: dark,
              onTap: () => Get.to(() => TwoFaSetupScreen()),
            ),
          ]),
          section('Account', [
            _SecurityRow(
              icon: Icons.lock_reset_rounded,
              title: 'Reset Password', subtitle: 'Update your account password',
              dark: dark,
              onTap: () => Get.to(() => ResetpasswordPage(username: controller.username.value)),
            ),
          ]),
          Center(child: Text('Your account security matters',
            style: TextStyle(color: muted, fontSize: 11))),
        ],
      )),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon, required this.title, required this.subtitle,
    required this.dark, this.onTap, this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF89919D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(icon, color: ink, size: 21),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: ink, fontSize: 14,
                fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: muted, fontSize: 11.5,
                height: 1.35)),
            ])),
            const SizedBox(width: 8),
            trailing ?? Icon(Icons.chevron_right_rounded, size: 19, color: muted),
          ]),
        ),
      ),
    );
  }
}
