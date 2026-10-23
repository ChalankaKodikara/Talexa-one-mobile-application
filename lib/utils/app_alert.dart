import 'dart:async';

import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppAlertType { info, success, warning, error, confirm }

class AppAlertAction {
  const AppAlertAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
}

/// Shared Talexa dialogs and floating notifications.
/// Existing show(), confirm(), toast(), and detail() call sites remain valid.
class AppAlert {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

  static const Color _blue = Color(0xFF1769E8);

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    AppAlertType type = AppAlertType.info,
    Widget? content,
    List<Widget> details = const [],
    List<AppAlertAction> actions = const [],
    String closeText = 'Close',
    bool barrierDismissible = true,
  }) {
    final effectiveActions = actions.isEmpty
        ? [
            AppAlertAction(
              label: closeText,
              isPrimary: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ]
        : actions;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF1B2638) : Colors.white;
        final ink = isDark ? Colors.white : const Color(0xFF182237);
        final muted = isDark ? Colors.white60 : const Color(0xFF89919D);
        final accent = _color(type);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFF0F2F5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 58,
                        width: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(isDark ? 0.18 : 0.09),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(type), color: accent, size: 28),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title.trim().isEmpty ? _title(type) : title.trim(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    if (message != null && message.trim().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        message.trim(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 22),
                      content,
                    ],
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _DetailsPanel(children: details),
                    ],
                    const SizedBox(height: 26),
                    _ActionRow(actions: effectiveActions),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      type: isDestructive ? AppAlertType.error : AppAlertType.confirm,
      actions: [
        AppAlertAction(
          label: cancelText,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        AppAlertAction(
          label: confirmText,
          isPrimary: true,
          isDestructive: isDestructive,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );
  }

  static void _dismissToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    final previous = _toastEntry;
    _toastEntry = null;
    if (previous != null) {
      previous.remove();
      previous.dispose();
    }
  }

  static void toast({
    required String title,
    required String message,
    AppAlertType? type,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = Get.overlayContext ?? Get.context;
    final overlay = Get.key.currentState?.overlay ??
        (context == null ? null : Overlay.maybeOf(context, rootOverlay: true));
    if (overlay == null) return;

    _dismissToast();

    final alertType = type ?? _typeFromTitle(title);
    final accent = _color(alertType);
    late final OverlayEntry entry;
    bool removed = false;

    void close() {
      if (removed) return;
      removed = true;
      if (identical(_toastEntry, entry)) {
        _toastTimer?.cancel();
        _toastTimer = null;
        _toastEntry = null;
      }
      entry.remove();
      entry.dispose();
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(overlayContext);
        final dark = theme.brightness == Brightness.dark;
        final surface = dark ? const Color(0xFF1B2638) : Colors.white;
        final ink = dark ? Colors.white : const Color(0xFF182237);
        final muted = dark ? Colors.white60 : const Color(0xFF89919D);
        final bottomInset = MediaQuery.of(overlayContext).padding.bottom;

        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + 18,
          child: SafeArea(
            top: false,
            bottom: false,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => Transform.translate(
                offset: Offset(0, 28 * progress),
                child: Opacity(opacity: 1 - progress, child: child),
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 15, 8, 15),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color:
                              dark ? Colors.white12 : const Color(0xFFEBEFF5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(dark ? 0.30 : 0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(dark ? 0.18 : 0.10),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(_icon(alertType), color: accent, size: 23),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.trim().isEmpty
                                      ? _title(alertType)
                                      : title.trim(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (message.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    message.trim(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dismiss notification',
                            onPressed: close,
                            icon: Icon(Icons.close_rounded,
                                color: muted, size: 19),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _toastEntry = entry;
    overlay.insert(entry);
    _toastTimer = Timer(duration, close);
  }

  static Widget detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.58),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _color(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return AppColors.success;
      case AppAlertType.warning:
      case AppAlertType.confirm:
        return AppColors.warning;
      case AppAlertType.error:
        return AppColors.danger;
      case AppAlertType.info:
        return _blue;
    }
  }

  static IconData _icon(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return Icons.check_circle_outline_rounded;
      case AppAlertType.warning:
        return Icons.warning_amber_rounded;
      case AppAlertType.confirm:
        return Icons.help_outline_rounded;
      case AppAlertType.error:
        return Icons.error_outline_rounded;
      case AppAlertType.info:
        return Icons.info_outline_rounded;
    }
  }

  static AppAlertType _typeFromTitle(String title) {
    final value = title.toLowerCase().trim();
    if (value.contains('success') ||
        value.contains('saved') ||
        value.contains('submitted') ||
        value.contains('enabled') ||
        value.contains('otp sent') ||
        value.contains('disabled')) {
      return AppAlertType.success;
    }
    if (value.contains('warning') ||
        value.contains('limit') ||
        value.contains('cancel')) {
      return AppAlertType.warning;
    }
    if (value.contains('error') ||
        value.contains('failed') ||
        value.contains('invalid') ||
        value.contains('required') ||
        value.contains('denied')) {
      return AppAlertType.error;
    }
    return AppAlertType.info;
  }

  static String _title(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return 'Success';
      case AppAlertType.warning:
        return 'Warning';
      case AppAlertType.error:
        return 'Error';
      case AppAlertType.confirm:
        return 'Confirm';
      case AppAlertType.info:
        return 'Info';
    }
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF263449) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});
  final List<AppAlertAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    // Wrap supports callers that provide more than two actions.
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: actions.map((action) {
        final width = actions.length == 1
            ? 320.0
            : actions.length == 2
                ? 130.0
                : 110.0;
        return SizedBox(
          width: width,
          height: 49,
          child: action.isPrimary
              ? ElevatedButton(
                  onPressed: action.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action.isDestructive
                        ? AppColors.danger
                        : AppAlert._blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                )
              : OutlinedButton(
                  onPressed: action.onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        action.isDestructive ? AppColors.danger : ink,
                    side: BorderSide(color: ink.withOpacity(0.13)),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
        );
      }).toList(),
    );
  }
}
