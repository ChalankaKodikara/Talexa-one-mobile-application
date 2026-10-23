import 'dart:async';

import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppAlertType {
  info,
  success,
  warning,
  error,
  confirm,
}

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

class AppAlert {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final alertColor = _color(type);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveActions = actions.isEmpty
        ? [
            AppAlertAction(
              label: closeText,
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
        : actions;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Material(
              color: colorScheme.surface,
              elevation: 16,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    color: alertColor,
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: alertColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _icon(type),
                                  color: alertColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (message != null &&
                                        message.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        message.trim(),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.72),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (content != null) ...[
                            const SizedBox(height: 18),
                            content,
                          ],
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _DetailsPanel(children: details),
                          ],
                          const SizedBox(height: 20),
                          _ActionRow(actions: effectiveActions),
                        ],
                      ),
                    ),
                  ),
                ],
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
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppAlertAction(
          label: confirmText,
          isPrimary: true,
          isDestructive: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  static void toast({
    required String title,
    required String message,
    AppAlertType? type,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = Get.context ?? Get.overlayContext;
    final overlay = Get.key.currentState?.overlay ??
        (context == null
            ? null
            : Overlay.maybeOf(context, rootOverlay: true)) ??
        (context == null ? null : Overlay.maybeOf(context));

    if (context == null || overlay == null) {
      return;
    }

    _toastTimer?.cancel();
    _toastEntry?.remove();

    final alertType = type ?? _typeFromTitle(title);
    final color = _color(alertType);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    late final OverlayEntry entry;

    void close() {
      _toastTimer?.cancel();
      if (_toastEntry == entry) {
        _toastEntry = null;
      }
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 22, end: 0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(0, offset),
                child: AnimatedOpacity(
                  opacity: offset == 0 ? 1 : 0.65,
                  duration: const Duration(milliseconds: 180),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.38 : 0.18,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          right: null,
                          child: ColoredBox(
                            color: color,
                            child: const SizedBox(width: 4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _icon(alertType),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.trim().isEmpty
                                          ? _title(alertType)
                                          : title.trim(),
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (message.trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        message.trim(),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.72),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Close',
                                onPressed: close,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.56,
                                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.58),
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
        return AppColors.primary1;
    }
  }

  static IconData _icon(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return Icons.check_circle_rounded;
      case AppAlertType.warning:
      case AppAlertType.confirm:
        return Icons.warning_amber_rounded;
      case AppAlertType.error:
        return Icons.error_rounded;
      case AppAlertType.info:
        return Icons.info_rounded;
    }
  }

  static AppAlertType _typeFromTitle(String title) {
    final normalized = title.toLowerCase().trim();

    if (normalized.contains('success') ||
        normalized.contains('saved') ||
        normalized.contains('submitted') ||
        normalized.contains('enabled')) {
      return AppAlertType.success;
    }

    if (normalized.contains('warning') ||
        normalized.contains('limit') ||
        normalized.contains('cancel')) {
      return AppAlertType.warning;
    }

    if (normalized.contains('error') ||
        normalized.contains('failed') ||
        normalized.contains('invalid')) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});

  final List<AppAlertAction> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: actions[i].isPrimary
                ? ElevatedButton(
                    onPressed: actions[i].onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actions[i].isDestructive
                          ? AppColors.danger
                          : AppColors.primary1,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actions[i].label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : OutlinedButton(
                    onPressed: actions[i].onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: actions[i].isDestructive
                          ? AppColors.danger
                          : colorScheme.onSurface,
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actions[i].label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
