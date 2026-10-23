import 'package:corehris/modules/HRMS/main_screens/subpages/security/controllers/pinsetup_con.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({
    super.key,
    required this.username,
  });

  final String username;

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  static const Color blue = Color(0xFF1769E8);

  late final PinSetupController controller;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _showPin = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<PinSetupController>()
        ? Get.find<PinSetupController>()
        : Get.put(PinSetupController());
  }

  @override
  void dispose() {
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _submitPin() {
    if (controller.isLoading.value) return;

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    controller.setupPin();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);

    final Color surface = isDark ? const Color(0xFF1B2638) : Colors.white;

    final Color ink = isDark ? Colors.white : const Color(0xFF182237);

    final Color muted = isDark ? Colors.white60 : const Color(0xFF89919D);

    final Color line = isDark ? Colors.white12 : const Color(0xFFECEFF3);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Setup PIN',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: bg,
        foregroundColor: ink,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 38,
                    color: blue,
                  ),
                ),
                const SizedBox(height: 19),
                Center(
                  child: Text(
                    'Secure your sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Choose a 4-digit PIN for faster access '
                    'to your workspace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                ),
                if (widget.username.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Center(
                    child: Text(
                      widget.username,
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'PIN DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.65,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    22,
                    18,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pinField(
                        label: 'Enter PIN',
                        ctrl: controller.pinController,
                        focusNode: _pinFocusNode,
                        nextFocusNode: _confirmFocusNode,
                        visible: _showPin,
                        onToggle: () {
                          setState(() => _showPin = !_showPin);
                        },
                        ink: ink,
                        muted: muted,
                        line: line,
                        isConfirm: false,
                      ),
                      const SizedBox(height: 27),
                      _pinField(
                        label: 'Confirm PIN',
                        ctrl: controller.confirmPinController,
                        focusNode: _confirmFocusNode,
                        visible: _showConfirm,
                        onToggle: () {
                          setState(
                            () => _showConfirm = !_showConfirm,
                          );
                        },
                        ink: ink,
                        muted: muted,
                        line: line,
                        isConfirm: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final bool isLoading = controller.isLoading.value;

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: blue.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: muted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Never share your PIN with anyone.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinField({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required bool visible,
    required VoidCallback onToggle,
    required Color ink,
    required Color muted,
    required Color line,
    required bool isConfirm,
  }) {
    return FormField<String>(
      validator: (_) {
        final value = ctrl.text.trim();

        if (!RegExp(r'^\d{4}$').hasMatch(value)) {
          return 'Please enter exactly 4 digits';
        }

        if (isConfirm && value != controller.pinController.text.trim()) {
          return 'PINs do not match';
        }

        return null;
      },
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) {
                final String pin = ctrl.text;

                return AnimatedBuilder(
                  animation: focusNode,
                  builder: (context, _) {
                    final bool focused = focusNode.hasFocus;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        FocusScope.of(context).requestFocus(focusNode);
                      },
                      child: Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: focused ? blue : line,
                              width: focused ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Real input receives keyboard events.
                            // Text is transparent; the PIN indicators
                            // are rendered separately.
                            Positioned.fill(
                              child: TextField(
                                controller: ctrl,
                                focusNode: focusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: isConfirm
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                    4,
                                  ),
                                ],
                                showCursor: false,
                                enableInteractiveSelection: false,
                                style: const TextStyle(
                                  color: Colors.transparent,
                                  fontSize: 20,
                                ),
                                cursorColor: Colors.transparent,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 19,
                                  ),
                                ),
                                onChanged: (value) {
                                  fieldState.didChange(value);

                                  if (value.length == 4 &&
                                      nextFocusNode != null) {
                                    FocusScope.of(context).requestFocus(
                                      nextFocusNode,
                                    );
                                  }
                                },
                                onSubmitted: (_) {
                                  if (isConfirm) {
                                    _submitPin();
                                  }
                                },
                              ),
                            ),

                            IgnorePointer(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        4,
                                        (index) {
                                          final bool filled =
                                              index < pin.length;

                                          return _PinIndicator(
                                            filled: filled,
                                            digit: visible && filled
                                                ? pin[index]
                                                : null,
                                            activeColor: blue,
                                            inactiveColor:
                                                muted.withOpacity(0.35),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),

                            Positioned(
                              right: 0,
                              child: IconButton(
                                tooltip: visible ? 'Hide PIN' : 'Show PIN',
                                onPressed: onToggle,
                                icon: Icon(
                                  visible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (fieldState.hasError) ...[
              const SizedBox(height: 9),
              Text(
                fieldState.errorText!,
                style: const TextStyle(
                  color: Color(0xFFD64550),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PinIndicator extends StatelessWidget {
  const _PinIndicator({
    required this.filled,
    required this.activeColor,
    required this.inactiveColor,
    this.digit,
  });

  final bool filled;
  final String? digit;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 32,
      child: Center(
        child: digit != null
            ? Text(
                digit!,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              )
            : AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                curve: Curves.easeOut,
                width: filled ? 11 : 9,
                height: filled ? 11 : 9,
                decoration: BoxDecoration(
                  color: filled ? activeColor : inactiveColor,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
