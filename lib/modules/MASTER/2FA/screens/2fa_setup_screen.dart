// ignore_for_file: use_super_parameters

import 'package:corehris/modules/MASTER/2FA/controllers/2fa_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TwoFaSetupScreen extends StatelessWidget {
  TwoFaSetupScreen({Key? key}) : super(key: key);

  final TwoFaController c = Get.put(TwoFaController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Two-Factor Authentication"),
        centerTitle: true,
      ),
      body: Obx(() => Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMainCard(),
                    const SizedBox(height: 20),
                    _buildAnimatedOtpPanel(),
                  ],
                ),
              ),

              // 🔥 Loading Overlay
              AnimatedOpacity(
                opacity: c.isProcessing.value ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !c.isProcessing.value,
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  // ===============================
  // MAIN TOGGLE CARD
  // ===============================
  Widget _buildMainCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => SwitchListTile(
              value: c.isEnabled.value,
              title: const Text(
                "Two-Factor Authentication",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                c.isEnabled.value
                    ? "Your account is protected with 2FA"
                    : "Add extra security to your account",
              ),

              // ✅ Disable switch while processing
              onChanged: c.isProcessing.value
                  ? null
                  : (value) {
                      c.toggleSwitch(value);
                    },
            )),
      ),
    );
  }

  // ===============================
  // ANIMATED OTP PANEL
  // ===============================
  Widget _buildAnimatedOtpPanel() {
    return Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: c.isSettingUp.value ? _buildOtpPanel() : const SizedBox(),
        ));
  }

  // ===============================
  // OTP CARD
  // ===============================
  Widget _buildOtpPanel() {
    return Card(
      key: const ValueKey("otpPanel"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Enter Verification Code",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              "A 6-digit code has been sent to your email.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: c.otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: c.isProcessing.value ? null : c.confirmEnable,
                    child: const Text("Confirm & Enable"),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: c.isProcessing.value ? null : c.cancelSetup,
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
