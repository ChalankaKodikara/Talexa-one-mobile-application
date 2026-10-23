import 'dart:math' as math;

import 'package:corehris/modules/HRMS/lock_screen/controller/logincon.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/forgot_screen.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/pinlogin_page.dart';
import 'package:flutter/material.dart';
import 'package:corehris/theme/theme.dart' show talexaFontFamily;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

/// Talexa HRMS authentication landing page.
/// Preserves the existing LoginController, PIN screen and recovery flow.
/// Continue with Email opens the email/password form on this same page.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF182237);
  static const _muted = Color(0xFF7E8CA2);
  static const _soft = Color(0xFFE8F2FF);
  static const _accent = Color(0xFF1769E8);
  static const _outline = Color(0xFFDDE8F8);
  static const _errorColor = Color(0xFFBA3442);

  late final LoginController controller;
  late final AnimationController _entrance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _emailMode = false;

  TextStyle _type(double size,
          {FontWeight weight = FontWeight.w400,
          Color color = _ink,
          double? height,
          double? spacing}) =>
      TextStyle(
          fontFamily: talexaFontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: spacing);

  static const _systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.white,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  void initState() {
    super.initState();
    // Android navigation bar is managed by the system, outside Scaffold.
    SystemChrome.setSystemUIOverlayStyle(_systemBars);
    controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());
    _email.text = controller.username.value;
    _password.text = controller.password.value;
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _openEmail() {
    if (_emailMode || controller.isLoading.value) return;
    HapticFeedback.selectionClick();
    setState(() => _emailMode = true);
  }

  void _backToMethods() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _emailMode = false);
  }

  void _signIn() {
    if (controller.isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    controller.username.value = _email.text.trim();
    controller.password.value = _password.text;
    HapticFeedback.selectionClick();
    controller.login();
  }

  void _openForgot() {
    if (controller.isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(_smoothRoute(
      ForgotPasswordScreen(initialEmail: _email.text.trim()),
    ));
  }

  Widget _brand() => Row(
        mainAxisSize: MainAxisSize.min,
        // children: [
        //   Container(
        //     width: 34,
        //     height: 34,
        //     decoration: BoxDecoration(
        //         color: _accent, borderRadius: BorderRadius.circular(11)),
        //     child: const Icon(Icons.auto_awesome_mosaic_rounded,
        //         color: Colors.white, size: 19),
        //   ),
        //   const SizedBox(width: 9),
        //   Text('talexa',
        //       style: _type(21, weight: FontWeight.w700, spacing: -0.9)),
        //   const SizedBox(width: 8),
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        //     decoration: BoxDecoration(
        //         color: _soft, borderRadius: BorderRadius.circular(20)),
        //     child: Text('', style: _type(9, weight: FontWeight.w600)),
        //   ),
        // ],
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom > 0;
    final shortScreen = media.size.height < 730;
    return PopScope(
      canPop: !_emailMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _emailMode) _backToMethods();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _systemBars,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Starts BEHIND the transparent status bar and fades into the
              // white login sheet, avoiding a visible status-bar color seam.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.36, 0.65, 1.0],
                      colors: [
                        Color(0xFFE5F1FF),
                        Color(0xFFF1F7FF),
                        Color(0xFFF7FAFF),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: true,
                bottom: true,
                child: LayoutBuilder(
                  builder: (context, limits) {
                    // Fit the artwork and card within the usable height when possible.
                    // The page can still scroll on very short devices and when the
                    // keyboard is visible.
                    final usableHeight = limits.maxHeight;
                    // Keep enough room for the card even on compact Androids.
                    // Very small devices stay scrollable instead of clipping.
                    final headerHeight = keyboard
                        ? 16.0
                        : _emailMode
                            ? (usableHeight * .16).clamp(72.0, 135.0)
                            : (usableHeight - (shortScreen ? 382.0 : 400.0))
                                .clamp(155.0, 355.0);
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: limits.maxHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 490),
                            child: Column(
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 460),
                                  curve: Curves.easeInOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: headerHeight,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 360),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                      child: !_emailMode && !keyboard
                                          ? _illustration(headerHeight)
                                          : Center(
                                              key: const ValueKey(
                                                  'compact-header'),
                                              child: _brand(),
                                            ),
                                    ),
                                  ),
                                ),
                                FadeTransition(
                                  opacity: CurvedAnimation(
                                      parent: _entrance, curve: Curves.easeOut),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 460),
                                    curve: Curves.easeInOutCubic,
                                    width: double.infinity,
                                    constraints: BoxConstraints(
                                      minHeight: keyboard
                                          ? 0
                                          : math.max(0,
                                              limits.maxHeight - headerHeight),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      24,
                                      shortScreen ? 18 : 25,
                                      24,
                                      shortScreen ? 16 : 24,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(36),
                                        topRight: Radius.circular(36),
                                      ),
                                    ),
                                    child: AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 460),
                                      curve: Curves.easeInOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 380),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        layoutBuilder:
                                            (currentChild, previousChildren) =>
                                                Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        ),
                                        transitionBuilder: (child, animation) {
                                          final isEmail = child.key ==
                                              const ValueKey('email');
                                          final offset = Tween<Offset>(
                                            begin: Offset(
                                                isEmail ? .11 : -.11, .025),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ));
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: offset,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _emailMode
                                            ? _emailContent(
                                                key: const ValueKey('email'))
                                            : _methodsContent(
                                                key: const ValueKey('methods')),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ), // LayoutBuilder
              ), // SafeArea
            ], // Stack children
          ), // Stack
        ), // Scaffold
      ), // AnnotatedRegion
    );
  }

  /// Decorative UI constructed with Flutter widgets—no external image assets.
  /// Responsive decorative header, keeping everything away from status bar.
  Widget _illustration(double height) => ClipRect(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final w = bounds.maxWidth;
            final scale = (height / 370).clamp(.52, 1.0);
            final middle = w / 2;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // The full-screen background gradient remains visible here.
                Positioned(top: 18, left: 24, child: _brand()),
                Positioned(
                  top: height * .30,
                  left: middle - 152 * scale,
                  child: Container(
                    width: 304 * scale,
                    height: 304 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.8)),
                    ),
                  ),
                ),
                Positioned(
                  top: height * .44,
                  left: middle - 100 * scale,
                  child: Container(
                    width: 200 * scale,
                    height: 200 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.8)),
                    ),
                  ),
                ),
                Positioned(
                  top: height * .35,
                  left: w * .17,
                  child: Transform.scale(
                    scale: scale,
                    child: _floating(Icons.work_outline_rounded,
                        const Color(0xFFDDEBFF), -.18),
                  ),
                ),
                Positioned(
                  top: height * .35,
                  right: w * .15,
                  child: Transform.scale(
                    scale: scale,
                    child: _floating(Icons.people_alt_outlined,
                        const Color(0xFFC9E0FF), .13),
                  ),
                ),
                Positioned(
                  top: height * .64,
                  left: w * .25,
                  child: Transform.scale(
                    scale: scale,
                    child: _floating(Icons.event_available_outlined,
                        const Color(0xFFE8F2FF), .12),
                  ),
                ),
                Positioned(
                  top: height * .66,
                  right: w * .24,
                  child: Transform.scale(
                    scale: scale,
                    child: _floating(Icons.insert_chart_outlined_rounded,
                        const Color(0xFFB9D8FF), -.15),
                  ),
                ),
                Positioned(
                  top: height * .78,
                  left: middle - 33 * scale,
                  child: Container(
                    width: 66 * scale,
                    height: 66 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: _accent, size: 30 * scale),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _floating(IconData icon, Color color, double rotation) =>
      Transform.rotate(
          angle: rotation,
          child: Container(
            width: 61,
            height: 61,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ]),
            child: Icon(icon, size: 29, color: _accent),
          ));

  Widget _methodsContent({Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Welcome Back',
              style: _type(27, weight: FontWeight.w600, spacing: -1.25)),
          const SizedBox(height: 5),
          Text('Sign in to manage your workday.',
              style: _type(13, color: _muted, height: 1.55)),
          const SizedBox(height: 23),
          Obx(() => _error(controller.loginError.value)),
          _primary('Continue with Email', _openEmail),
          const SizedBox(height: 10),
          Obx(() {
            final busy = controller.isLoading.value;
            final available = controller.availableBiometrics;
            final hasFace = available.contains(BiometricType.face);
            final hasFinger = available.contains(BiometricType.fingerprint);
            final icon = hasFace
                ? Icons.face_outlined
                : hasFinger
                    ? Icons.fingerprint_rounded
                    : Icons.fingerprint_rounded;
            return Row(
              children: [
                Expanded(
                    child: _option(
                  icon: Icons.dialpad_rounded,
                  label: 'PIN Login',
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            _smoothRoute(const PinLoginScreen()),
                          );
                        },
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _option(
                  icon: icon,
                  label: hasFace
                      ? 'Face ID'
                      : hasFinger
                          ? 'Fingerprint'
                          : 'Biometric',
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          controller.loginWithBiometric();
                        },
                )),
              ],
            );
          }),
          const SizedBox(height: 9),
          Center(
              child: TextButton(
            onPressed: _openForgot,
            style: TextButton.styleFrom(foregroundColor: _accent),
            child: Text('Forgot password?',
                style: _type(12, color: _accent, weight: FontWeight.w600)),
          )),
          const SizedBox(height: 7),
          _footer(),
        ],
      );

  Widget _emailContent({Key? key}) => Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            IconButton(
              onPressed: _backToMethods,
              tooltip: 'Back to login methods',
              style: IconButton.styleFrom(backgroundColor: _soft),
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 21, color: _accent),
            ),
            const SizedBox(width: 9),
            Text('Email login', style: _type(13, weight: FontWeight.w600)),
          ]),
          const SizedBox(height: 24),
          Text('Continue with Email',
              style: _type(25, weight: FontWeight.w600, spacing: -1)),
          const SizedBox(height: 5),
          Text('Sign in to manage your workday.',
              style: _type(12.5, color: _muted)),
          const SizedBox(height: 24),
          Obx(() => _error(controller.loginError.value)),
          _label('Email or username'),
          const SizedBox(height: 8),
          Obx(() => _field(
                editing: _email,
                focus: _emailFocus,
                hint: 'Enter your email or username',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.username, AutofillHints.email],
                error: controller.usernameError.value,
                onChanged: (v) {
                  controller.username.value = v;
                  controller.clearUsernameError();
                },
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              )),
          const SizedBox(height: 18),
          _label('Password'),
          const SizedBox(height: 8),
          Obx(() => _field(
                editing: _password,
                focus: _passwordFocus,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                keyboard: TextInputType.visiblePassword,
                autofill: const [AutofillHints.password],
                obscure: controller.isPasswordHidden.value,
                error: controller.passwordError.value,
                onChanged: (v) {
                  controller.password.value = v;
                  controller.clearPasswordError();
                },
                onSubmitted: (_) => _signIn(),
                suffix: IconButton(
                  tooltip: controller.isPasswordHidden.value
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _muted,
                      size: 21),
                ),
              )),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openForgot,
                child: Text('Forgot password?',
                    style:
                        _type(11.5, color: _accent, weight: FontWeight.w600)),
              )),
          const SizedBox(height: 7),
          Obx(() => _primary(
              'Sign in', controller.isLoading.value ? null : _signIn,
              loading: controller.isLoading.value)),
          const SizedBox(height: 25),
          _footer(),
        ],
      );

  /// Slide in softly from the right while fading, with reverse animation.
  Route<T> _smoothRoute<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.12, .025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );

  Widget _footer() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: _muted,
              ),
              const SizedBox(width: 5),
              Text(
                'Secure access to your workspace',
                style: _type(10, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Powered by',
            style: _type(
              10,
              color: _muted,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Image.asset(
            'assets/images/talentfort_logo.png',
            width: 148,
            height: 36,
            fit: BoxFit.contain,
            semanticLabel: 'Talentfort',
          ),
        ],
      );

  Widget _label(String text) =>
      Text(text, style: _type(11.5, weight: FontWeight.w600));

  Widget _error(String message) => message.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.error_outline, color: _errorColor, size: 19),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(message, style: _type(11.5, color: _errorColor))),
            ]),
          ),
        );

  Widget _primary(String text, VoidCallback? onPressed,
          {bool loading = false}) =>
      SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF92B9F8),
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.2))
              : Text(text,
                  style:
                      _type(13, weight: FontWeight.w500, color: Colors.white)),
        ),
      );

  Widget _option({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) =>
      SizedBox(
        height: 54,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _ink,
            disabledForegroundColor: _muted,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _type(11, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _field(
      {required TextEditingController editing,
      required FocusNode focus,
      required String hint,
      required IconData icon,
      required TextInputType keyboard,
      required Iterable<String> autofill,
      required String error,
      required ValueChanged<String> onChanged,
      required ValueChanged<String> onSubmitted,
      bool obscure = false,
      Widget? suffix}) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(color: color, width: width));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: editing,
        focusNode: focus,
        keyboardType: keyboard,
        obscureText: obscure,
        enableSuggestions: !obscure,
        autocorrect: false,
        autofillHints: autofill,
        textInputAction: keyboard == TextInputType.emailAddress
            ? TextInputAction.next
            : TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: _type(12.5),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: _type(11.5, color: _muted),
          prefixIcon: Icon(icon, color: _muted, size: 19),
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 17, horizontal: 13),
          enabledBorder: outline(_outline),
          focusedBorder: outline(_accent, 1.6),
          border: outline(_outline),
        ),
      ),
      if (error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 3),
          child: Text(error, style: _type(10.5, color: _errorColor)),
        ),
    ]);
  }
}
