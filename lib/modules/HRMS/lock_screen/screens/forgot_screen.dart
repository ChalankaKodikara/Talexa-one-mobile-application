// Talexa HRMS - Blue & White forgot-password flow
import 'dart:io' show Platform;
import 'package:corehris/modules/HRMS/lock_screen/controller/forgot_con.dart';
import 'package:flutter/material.dart';
import 'package:corehris/theme/theme.dart' show talexaFontFamily;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  static const blue = Color(0xFF1769E8);
  static const navy = Color(0xFF123B75);
  static const pale = Color(0xFFE8F2FF);
  static const ink = Color(0xFF182237);
  late final ForgotPasswordController controller;
  late final AnimationController entrance;
  late final TextEditingController emailText;
  final otpText = TextEditingController();
  final newText = TextEditingController();
  final confirmText = TextEditingController();

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
    controller = Get.put(ForgotPasswordController());
    final initial = widget.initialEmail?.trim() ?? '';
    controller.email.value = initial;
    emailText = TextEditingController(text: initial);
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    entrance.dispose();
    emailText.dispose();
    otpText.dispose();
    newText.dispose();
    confirmText.dispose();
    // GetX owns the controller lifecycle after navigation.
    super.dispose();
  }

  InputDecoration fieldDecoration(
      {required String hint,
      required IconData icon,
      required Color surface,
      required Color border,
      required Color muted,
      Widget? suffix,
      String? error}) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: color, width: width));
    return InputDecoration(
      hintText: hint,
      hintStyle: type(12, color: muted),
      filled: true,
      fillColor: surface,
      prefixIcon: Icon(icon, color: blue),
      suffixIcon: suffix,
      errorText: error?.isEmpty == true ? null : error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: outline(border),
      border: outline(border),
      focusedBorder: outline(blue, 1.6),
      errorBorder: outline(const Color(0xFFD74756)),
      focusedErrorBorder: outline(const Color(0xFFD74756), 1.5),
    );
  }

  Widget inputLabel(String label, Color text) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child:
          Text(label, style: type(12, weight: FontWeight.w700, color: text)));

  Widget primary(String label, VoidCallback action, bool loading) => SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
          onPressed: loading
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  HapticFeedback.selectionClick();
                  action();
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: blue.withOpacity(.55),
              shape: const StadiumBorder()),
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('progress'),
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text(label,
                              style: type(14,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18)
                        ]))));

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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: Platform.isIOS
                ? const BouncingScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: FadeTransition(
                  opacity:
                      CurvedAnimation(parent: entrance, curve: Curves.easeOut),
                  child: Obx(() {
                    final step = controller.currentStep.value;
                    final number = controller.stepNumber;
                    final loading = controller.isLoading.value;
                    final isEmail = step == ForgotPasswordStep.email;
                    final isOtp = step == ForgotPasswordStep.otp;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 17),
                          Row(children: [
                            IconButton(
                                tooltip: 'Back',
                                onPressed: loading ? null : controller.goBack,
                                style: IconButton.styleFrom(
                                    backgroundColor: dark ? surface : pale,
                                    foregroundColor: blue,
                                    minimumSize: const Size(46, 46)),
                                icon: const Icon(Icons.arrow_back_rounded)),
                            const SizedBox(width: 13),
                            Text('Account recovery',
                                style: type(16,
                                    weight: FontWeight.w700, color: text)),
                            const Spacer(),
                            Text('$number of 3',
                                style: type(12,
                                    weight: FontWeight.w600, color: muted)),
                          ]),
                          const SizedBox(height: 18),
                          Row(
                              children: List.generate(
                                  3,
                                  (i) => Expanded(
                                      child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 230),
                                          height: 5,
                                          margin: EdgeInsets.only(
                                              right: i == 2 ? 0 : 7),
                                          decoration: BoxDecoration(
                                              color: i < number ? blue : border,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20)))))),
                          const SizedBox(height: 42),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                      color:
                                          dark ? blue.withOpacity(.18) : pale,
                                      borderRadius: BorderRadius.circular(22)),
                                  child: Icon(
                                      isEmail
                                          ? Icons.lock_reset_rounded
                                          : isOtp
                                              ? Icons.mark_email_read_outlined
                                              : Icons.password_rounded,
                                      color: blue,
                                      size: 31))),
                          const SizedBox(height: 21),
                          AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: Column(
                                  key: ValueKey(number),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(controller.title,
                                        style: type(29,
                                            weight: FontWeight.w800,
                                            color: text)),
                                    const SizedBox(height: 9),
                                    Text(controller.description,
                                        style: type(13, color: muted)
                                            .copyWith(height: 1.55)),
                                  ])),
                          const SizedBox(height: 24),
                          if (controller.generalError.value.isNotEmpty) ...[
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: dark
                                        ? const Color(0xFF442B32)
                                        : const Color(0xFFFFF1F1),
                                    borderRadius: BorderRadius.circular(15)),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Color(0xFFD74756)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(controller.generalError.value,
                                          style: type(12,
                                              color: dark
                                                  ? Colors.white
                                                  : const Color(0xFF9D2734))))
                                ])),
                            const SizedBox(height: 22),
                          ],
                          if (isEmail) ...[
                            inputLabel('Email address', text),
                            TextField(
                                controller: emailText,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.email],
                                onChanged: (v) {
                                  controller.email.value = v;
                                  controller.clearEmailError();
                                },
                                onSubmitted: (_) {
                                  if (!loading) controller.sendOtp();
                                },
                                style: type(14, color: text),
                                decoration: fieldDecoration(
                                    hint: 'name@company.com',
                                    icon: Icons.alternate_email_rounded,
                                    surface: surface,
                                    border: border,
                                    muted: muted,
                                    error: controller.emailError.value)),
                            const SizedBox(height: 24),
                            primary('Send verification code',
                                controller.sendOtp, loading),
                          ] else if (isOtp) ...[
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: dark ? surface : pale,
                                    borderRadius: BorderRadius.circular(16)),
                                child: Row(children: [
                                  const Icon(Icons.mail_outline_rounded,
                                      color: blue),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(controller.email.value,
                                          style: type(12,
                                              weight: FontWeight.w600,
                                              color:
                                                  dark ? Colors.white : navy)))
                                ])),
                            const SizedBox(height: 22),
                            inputLabel('6-digit verification code', text),
                            TextField(
                                controller: otpText,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6)
                                ],
                                onChanged: (v) {
                                  controller.otp.value = v;
                                  controller.clearOtpError();
                                },
                                onSubmitted: (_) {
                                  if (!loading) controller.verifyOtp();
                                },
                                style: type(19,
                                        weight: FontWeight.w700, color: text)
                                    .copyWith(letterSpacing: 5),
                                decoration: fieldDecoration(
                                        hint: '000000',
                                        icon: Icons.password_rounded,
                                        surface: surface,
                                        border: border,
                                        muted: muted,
                                        error: controller.otpError.value)
                                    .copyWith(counterText: '')),
                            const SizedBox(height: 24),
                            primary(
                                'Verify code', controller.verifyOtp, loading),
                            const SizedBox(height: 14),
                            Center(
                                child: TextButton(
                                    onPressed:
                                        loading ? null : controller.resendOtp,
                                    child: Text('Resend code',
                                        style: type(12,
                                            weight: FontWeight.w700,
                                            color: blue)))),
                          ] else ...[
                            inputLabel('New password', text),
                            TextField(
                                controller: newText,
                                obscureText:
                                    controller.isNewPasswordHidden.value,
                                textInputAction: TextInputAction.next,
                                onChanged: (v) {
                                  controller.newPassword.value = v;
                                  controller.clearNewPasswordError();
                                },
                                style: type(14, color: text),
                                decoration: fieldDecoration(
                                    hint: 'Enter new password',
                                    icon: Icons.lock_outline_rounded,
                                    surface: surface,
                                    border: border,
                                    muted: muted,
                                    error: controller.newPasswordError.value,
                                    suffix: IconButton(
                                        onPressed: controller
                                            .toggleNewPasswordVisibility,
                                        icon: Icon(
                                            controller.isNewPasswordHidden.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: muted)))),
                            const SizedBox(height: 19),
                            inputLabel('Confirm password', text),
                            TextField(
                                controller: confirmText,
                                obscureText:
                                    controller.isConfirmPasswordHidden.value,
                                textInputAction: TextInputAction.done,
                                onChanged: (v) {
                                  controller.confirmPassword.value = v;
                                  controller.clearConfirmPasswordError();
                                },
                                onSubmitted: (_) {
                                  if (!loading) controller.setNewPassword();
                                },
                                style: type(14, color: text),
                                decoration: fieldDecoration(
                                    hint: 'Confirm new password',
                                    icon: Icons.lock_reset_rounded,
                                    surface: surface,
                                    border: border,
                                    muted: muted,
                                    error:
                                        controller.confirmPasswordError.value,
                                    suffix: IconButton(
                                        onPressed: controller
                                            .toggleConfirmPasswordVisibility,
                                        icon: Icon(
                                            controller.isConfirmPasswordHidden
                                                    .value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: muted)))),
                            const SizedBox(height: 15),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                    color: dark ? surface : pale,
                                    borderRadius: BorderRadius.circular(14)),
                                child: Row(children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: blue, size: 19),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(
                                          'Password must contain at least 6 characters.',
                                          style: type(12, color: muted)))
                                ])),
                            const SizedBox(height: 24),
                            primary('Update password',
                                controller.setNewPassword, loading),
                          ],
                          const SizedBox(height: 35),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: muted, size: 15),
                                const SizedBox(width: 7),
                                Flexible(
                                    child: Text('Secure account recovery',
                                        style: type(11, color: muted)))
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
                        ]);
                  }),
                ),
              )),
            ),
          );
        })),
      ),
    );
  }
}
