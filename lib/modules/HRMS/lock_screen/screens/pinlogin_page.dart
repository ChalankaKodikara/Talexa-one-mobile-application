// Talexa HRMS - Blue & White PIN login
import 'dart:io' show Platform;
import 'package:corehris/modules/HRMS/lock_screen/controller/logincon.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:corehris/theme/theme.dart' show talexaFontFamily;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen>
    with SingleTickerProviderStateMixin {
  static const blue = Color(0xFF1769E8);
  static const navy = Color(0xFF123B75);
  static const pale = Color(0xFFE8F2FF);
  static const ink = Color(0xFF182237);
  late final LoginController controller;
  final pinController = TextEditingController();
  final pinFocusNode = FocusNode();
  late final AnimationController entrance;
  String inlineError = '';

  TextStyle type(double size,
          {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(
          fontFamily: talexaFontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color);

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
  }

  @override
  void dispose() {
    entrance.dispose();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  void submit() {
    if (controller.isLoading.value) return;
    FocusScope.of(context).unfocus();
    final pin = pinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      HapticFeedback.mediumImpact();
      setState(() => inlineError = 'Enter your 4-digit PIN to continue.');
      AppAlert.toast(
          title: 'Invalid PIN', message: 'Please enter a 4-digit PIN');
      return;
    }
    setState(() => inlineError = '');
    HapticFeedback.selectionClick();
    controller.loginWithPin(pin);
  }

  void openPassword() {
    if (controller.isLoading.value) return;
    FocusScope.of(context).unfocus();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF7FAFF);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final text = dark ? Colors.white : ink;
    final muted = dark ? const Color(0xFFA8B8CD) : const Color(0xFF7E8CA2);
    final border = dark ? const Color(0xFF34445A) : const Color(0xFFDDE8F8);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: LayoutBuilder(builder: (context, viewport) {
          return SingleChildScrollView(
            physics: Platform.isIOS
                ? const BouncingScrollPhysics()
                : const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: FadeTransition(
                  opacity:
                      CurvedAnimation(parent: entrance, curve: Curves.easeOut),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 22),
                      // Row(children: [
                      //   Container(
                      //       width: 42,
                      //       height: 42,
                      //       decoration: BoxDecoration(
                      //           color: blue,
                      //           borderRadius: BorderRadius.circular(14)),
                      //       child: const Icon(Icons.work_rounded,
                      //           color: Colors.white, size: 21)),
                      //   const SizedBox(width: 11),
                      //   Text('talexa',
                      //       style:
                      //           type(22, weight: FontWeight.w800, color: text)),
                      //   const SizedBox(width: 6),
                      //   Text('HRMS',
                      //       style:
                      //           type(11, weight: FontWeight.w700, color: blue)),
                      //   const Spacer(),
                      //   IconButton(
                      //       tooltip: 'Password login',
                      //       onPressed: openPassword,
                      //       icon: const Icon(Icons.close_rounded)),
                      // ]),
                      SizedBox(height: viewport.maxHeight < 650 ? 24 : 42),
                      Text('Welcome back.',
                          textAlign: TextAlign.center,
                          style:
                              type(32, weight: FontWeight.w800, color: text)),
                      const SizedBox(height: 8),
                      Text('Enter your 4-digit PIN to access Talexa HRMS.',
                          textAlign: TextAlign.center,
                          style: type(13, color: muted)),
                      const SizedBox(height: 50),
                      // Text('Your PIN',
                      //     style:
                      //         type(12, weight: FontWeight.w700, color: text)),

                      const SizedBox(height: 10),

                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 65,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(4, (index) {
                                      final filled =
                                          index < pinController.text.length;

                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeInOut,
                                        width: filled ? 10 : 7,
                                        height: filled ? 10 : 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: filled
                                              ? blue
                                              : const Color(0xFF94A3B8),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    height: 2,
                                    width: 210,
                                    color: blue,
                                  ),
                                ],
                              ),
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    controller: pinController,
                                    focusNode: pinFocusNode,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 4,
                                    obscureText: true,
                                    showCursor: false,
                                    enableInteractiveSelection: false,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    onChanged: (_) {
                                      setState(() {
                                        inlineError = '';
                                      });
                                    },
                                    onSubmitted: (_) => submit(),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          child: inlineError.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 9),
                                  child: Text(inlineError,
                                      style: type(12,
                                          color: const Color(0xFFD74756))))),
                      const SizedBox(height: 24),
                      Obx(() => SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                controller.isLoading.value ? null : submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder()),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Text('Unlock with PIN',
                                            style: type(14,
                                                weight: FontWeight.w700,
                                                color: Colors.white)),
                                        const SizedBox(width: 9),
                                        const Icon(Icons.arrow_forward_rounded,
                                            size: 19)
                                      ]),
                          ))),
                      const SizedBox(height: 24),
                      Obx(() {
                        final available = controller.isBiometricEnabled.value &&
                            controller.availableBiometrics.isNotEmpty;
                        final face = controller.availableBiometrics
                            .contains(BiometricType.face);
                        if (!available) return const SizedBox.shrink();
                        return Column(children: [
                          Row(children: [
                            Expanded(child: Divider(color: border)),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or continue with',
                                    style: type(11, color: muted))),
                            Expanded(child: Divider(color: border))
                          ]),
                          const SizedBox(height: 18),
                          SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          HapticFeedback.selectionClick();
                                          controller.loginWithBiometric();
                                        },
                                  icon: Icon(
                                      face
                                          ? Icons.face_rounded
                                          : Icons.fingerprint_rounded,
                                      color: blue),
                                  label: Text(
                                      face
                                          ? 'Continue with Face ID'
                                          : 'Continue with fingerprint',
                                      style: type(12,
                                          weight: FontWeight.w600,
                                          color: text)),
                                  style: OutlinedButton.styleFrom(
                                      backgroundColor: surface,
                                      side: BorderSide(color: border),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18))))),
                        ]);
                      }),
                      const SizedBox(height: 19),
                      TextButton.icon(
                          onPressed: openPassword,
                          icon: const Icon(Icons.person_outline_rounded,
                              size: 19),
                          label: const Text('Use username & password'),
                          style: TextButton.styleFrom(foregroundColor: blue)),
                      const SizedBox(height: 30),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, color: muted, size: 15),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text(
                                    'Secure access to your organization',
                                    style: type(10, color: muted)))
                          ]),

                      const SizedBox(height: 25),

                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Powered by',
                              style: type(
                                10,
                                weight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Image.asset(
                              'assets/images/talentfort_logo.png',
                              width: 174,
                              height: 40,
                              fit: BoxFit.contain,
                              semanticLabel: 'Talentfort',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              )),
            ),
          );
        })),
      ),
    );
  }
}
