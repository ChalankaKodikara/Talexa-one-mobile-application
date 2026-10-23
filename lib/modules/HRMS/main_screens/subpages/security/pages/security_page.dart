// lib/modules/screens/main_screens/subpages/security/pages/security_page.dart
// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'package:corehris/modules/MASTER/2FA/screens/2fa_setup_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/resetpassword.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/controllers/security_con.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/pinsetup_page.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SecurityController controller = Get.isRegistered<SecurityController>()
        ? Get.find<SecurityController>()
        : Get.put(SecurityController());

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = colorScheme.surface;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withOpacity(0.70);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: titleColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(
          color: titleColor,
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          children: [
            _buildHeaderCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _buildSecurityOptionsCard(
              context,
              controller: controller,
              cardColor: cardColor,
              borderColor: borderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cardColor,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withOpacity(
        isDark ? 0.28 : 0.12,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary2.withOpacity(0.22),
                ),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppColors.primary2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure your account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Manage PIN, biometrics, two-factor authentication and password options.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOptionsCard(
    BuildContext context, {
    required SecurityController controller,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: cardColor,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withOpacity(
        isDark ? 0.28 : 0.12,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: borderColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSecurityTile(
            context,
            icon: Icons.pin_rounded,
            title: 'Set Up PIN',
            subtitle: 'Create or change your 4-digit PIN',
            iconBackgroundColor: AppColors.primary2.withOpacity(0.12),
            iconColor: AppColors.primary2,
            onTap: () {
              Get.to(
                () => PinSetupPage(
                  username: controller.username.value,
                ),
              );
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),
          Obx(() {
            final enabled = controller.isBiometricEnabled.value;
            final canUseBiometrics = controller.canUseBiometrics.value;

            final biometricColor = enabled
                ? AppColors.success
                : colorScheme.onSurface.withOpacity(0.45);

            return SwitchListTile.adaptive(
              value: enabled,
              onChanged: canUseBiometrics
                  ? (value) {
                      controller.toggleBiometric(value);
                    }
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              secondary: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: biometricColor.withOpacity(
                    isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: biometricColor.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: biometricColor,
                ),
              ),
              title: Text(
                'Biometric Login',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  canUseBiometrics
                      ? 'Use fingerprint or Face ID to log in'
                      : 'Biometrics are not available on this device',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: canUseBiometrics
                        ? subtitleColor
                        : colorScheme.error.withOpacity(0.9),
                  ),
                ),
              ),
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary2,
              inactiveThumbColor: isDark
                  ? Colors.white54
                  : colorScheme.onSurface.withOpacity(0.55),
              inactiveTrackColor: isDark
                  ? Colors.white24
                  : colorScheme.onSurface.withOpacity(0.14),
            );
          }),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),
          _buildSecurityTile(
            context,
            icon: Icons.phonelink_lock_rounded,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra verification step to your account',
            iconBackgroundColor: AppColors.success.withOpacity(0.12),
            iconColor: AppColors.success,
            onTap: () {
              Get.to(
                () => TwoFaSetupScreen(),
              );
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),
          _buildSecurityTile(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'Password Reset',
            subtitle: 'Change your account password',
            iconBackgroundColor: Colors.orange.withOpacity(0.14),
            iconColor: Colors.orange,
            onTap: () {
              Get.to(
                () => ResetpasswordPage(
                  username: controller.username.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iconColor.withOpacity(0.18),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colorScheme.onSurface.withOpacity(0.70),
          ),
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: colorScheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }
}
