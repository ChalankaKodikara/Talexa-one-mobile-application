// lib/modules/screens/main_screens/subpages/security/pinsetup_page.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/main_screens/subpages/security/controllers/pinsetup_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PinSetupPage extends StatelessWidget {
  final String username;

  const PinSetupPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // Fresh instance each time
    final PinSetupController controller =
        Get.put(PinSetupController(), permanent: false);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = cs.surface;
    final onCard = cs.onSurface;
    final subText = cs.onSurface.withOpacity(0.70);
    final border = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Setup PIN",
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: card,
        foregroundColor: onCard,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary2.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary2.withOpacity(0.22),
                        ),
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: AppColors.primary2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create a 4-digit PIN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: onCard,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Username: $username",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set a 4-digit PIN for quick and secure access.",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: subText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- Enter PIN ---
                    _pinField(
                      context,
                      label: "Enter PIN",
                      ctrl: controller.pinController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // --- Confirm PIN ---
                    _pinField(
                      context,
                      label: "Confirm PIN",
                      ctrl: controller.confirmPinController,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 18),

                    // --- Button ---
                    Obx(() {
                      final isLoading = controller.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: IgnorePointer(
                          ignoring: isLoading,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : controller.setupPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Set PIN",
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    Text(
                      "Tip: Don’t share your PIN with anyone.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinField(
    BuildContext context, {
    required String label,
    required TextEditingController ctrl,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TextField(
      controller: ctrl,
      obscureText: true,
      obscuringCharacter: "•",
      keyboardType: TextInputType.number,
      maxLength: 4,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 14,
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        prefixIcon: const Icon(Icons.pin, color: AppColors.primary2),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2236) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary2, width: 1.6),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withOpacity(0.60),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}
