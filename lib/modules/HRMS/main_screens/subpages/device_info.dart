import 'package:corehris/modules/HRMS/main_screens/subpages/controllers/view_profile_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceLogScreen extends StatefulWidget {
  const DeviceLogScreen({
    super.key,
  });

  @override
  State<DeviceLogScreen> createState() => _DeviceLogScreenState();
}

class _DeviceLogScreenState extends State<DeviceLogScreen> {
  late final ViewProfileController controller;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // GET EXISTING CONTROLLER OR REGISTER NEW ONE
    // ============================================================

    if (Get.isRegistered<ViewProfileController>()) {
      controller = Get.find<ViewProfileController>();
    } else {
      controller = Get.put(ViewProfileController());
    }

    // ============================================================
    // FETCH REGISTERED DEVICE
    // ============================================================

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await controller.fetchRegisteredDeviceInfo();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Registered Device',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: controller.isDeviceLoading.value
                  ? null
                  : () async {
                      await controller.fetchRegisteredDeviceInfo();
                    },
              icon: controller.isDeviceLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                    ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Obx(
        () {
          // ======================================================
          // LOADING
          // ======================================================

          if (controller.isDeviceLoading.value &&
              controller.registeredDevices.isEmpty) {
            return const _LoadingView();
          }

          // ======================================================
          // ERROR
          // ======================================================

          final String? error = controller.deviceError.value;

          if (error != null &&
              error.trim().isNotEmpty &&
              controller.registeredDevices.isEmpty) {
            return _ErrorView(
              message: error,
              onRetry: () async {
                await controller.fetchRegisteredDeviceInfo();
              },
            );
          }

          // ======================================================
          // EMPTY
          // ======================================================

          if (controller.registeredDevices.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.refreshDeviceInfo,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 100),
                  _EmptyDeviceView(),
                ],
              ),
            );
          }

          // ======================================================
          // REGISTERED DEVICES
          // ======================================================

          return RefreshIndicator(
            onRefresh: controller.refreshDeviceInfo,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                32,
              ),
              children: [
                // =================================================
                // HEADER
                // =================================================

                _RegisteredDeviceHeader(
                  count: controller.registeredDevices.length,
                ),

                const SizedBox(height: 14),

                // =================================================
                // DEVICE LIST
                // =================================================

                ...controller.registeredDevices.map(
                  (device) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _RegisteredDeviceCard(
                        device: device,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// REGISTERED DEVICE HEADER
/// ============================================================

class _RegisteredDeviceHeader extends StatelessWidget {
  const _RegisteredDeviceHeader({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // ========================================================
        // ICON
        // ========================================================

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2495FE).withOpacity(.16)
                : const Color(0xFF2495FE).withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.smartphone_rounded,
            size: 22,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1961AD),
          ),
        ),

        const SizedBox(width: 12),

        // ========================================================
        // TITLE
        // ========================================================

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registered Device',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 1
                    ? '1 device linked to your account'
                    : '$count devices linked to your account',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // COUNT
        // ========================================================

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1961AD),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// REGISTERED DEVICE CARD
/// ============================================================

class _RegisteredDeviceCard extends StatelessWidget {
  const _RegisteredDeviceCard({
    required this.device,
  });

  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    // ==========================================================
    // DEVICE VALUES
    // ==========================================================

    final String deviceName = _value(
      device,
      [
        'device_name',
        'deviceName',
        'name',
      ],
    );

    final String model = _value(
      device,
      [
        'model',
        'device_model',
        'deviceModel',
      ],
    );

    final String platform = _value(
      device,
      [
        'platform',
        'os',
        'operating_system',
      ],
    );

    final String osVersion = _value(
      device,
      [
        'os_version',
        'osVersion',
      ],
    );

    final String appVersion = _value(
      device,
      [
        'app_version',
        'appVersion',
      ],
    );

    final String deviceId = _value(
      device,
      [
        'device_id',
        'deviceId',
        'uuid',
        'identifier',
      ],
    );

    final String status = _value(
      device,
      [
        'status',
        'device_status',
      ],
    );

    final String registeredAt = _value(
      device,
      [
        'registered_at',
        'registeredAt',
        'created_at',
        'createdAt',
      ],
    );

    final String lastLoginAt = _value(
      device,
      [
        'last_login_at',
        'lastLoginAt',
        'last_login',
        'lastLogin',
      ],
    );

    final String lastSeenAt = _value(
      device,
      [
        'last_seen_at',
        'lastSeenAt',
        'last_seen',
        'lastSeen',
        'updated_at',
      ],
    );

    final String ipAddress = _value(
      device,
      [
        'last_ip_address',
        'lastIpAddress',
        'ip_address',
        'ipAddress',
        'ip',
      ],
    );

    // ==========================================================
    // UI
    // ==========================================================

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFE5E7EB),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.035),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          // ======================================================
          // DEVICE HEADER
          // ======================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // =================================================
                // DEVICE ICON
                // =================================================

                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _deviceIcon(platform),
                    size: 27,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1961AD),
                  ),
                ),

                const SizedBox(width: 13),

                // =================================================
                // NAME + MODEL
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName == '-' ? 'Registered Device' : deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deviceSubtitle(
                          model,
                          platform,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // =================================================
                // STATUS
                // =================================================

                _StatusBadge(
                  status: status,
                ),
              ],
            ),
          ),

          // ======================================================
          // DIVIDER
          // ======================================================

          _divider(context),

          // ======================================================
          // DETAILS
          // ======================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            child: Column(
              children: [
                // =================================================
                // DEVICE ID
                // =================================================

                _DeviceInfoRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'Device ID',
                  value: deviceId,
                ),

                _divider(context),

                // =================================================
                // MODEL
                // =================================================

                if (model != '-') ...[
                  _DeviceInfoRow(
                    icon: Icons.smartphone_outlined,
                    label: 'Model',
                    value: model,
                  ),
                  _divider(context),
                ],

                // =================================================
                // PLATFORM
                // =================================================

                _DeviceInfoRow(
                  icon: _deviceIcon(platform),
                  label: 'Platform',
                  value: platform,
                ),

                // =================================================
                // OS VERSION
                // =================================================

                if (osVersion != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.settings_outlined,
                    label: 'OS Version',
                    value: osVersion,
                  ),
                ],

                // =================================================
                // APP VERSION
                // =================================================

                if (appVersion != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.apps_rounded,
                    label: 'App Version',
                    value: appVersion,
                  ),
                ],

                // =================================================
                // REGISTERED DATE
                // =================================================

                if (registeredAt != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Registered',
                    value: _formatDateTime(
                      registeredAt,
                    ),
                  ),
                ],

                // =================================================
                // LAST LOGIN
                // =================================================

                if (lastLoginAt != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.login_rounded,
                    label: 'Last Login',
                    value: _formatDateTime(
                      lastLoginAt,
                    ),
                  ),
                ],

                // =================================================
                // LAST SEEN
                // =================================================

                if (lastSeenAt != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Last Seen',
                    value: _formatDateTime(
                      lastSeenAt,
                    ),
                  ),
                ],

                // =================================================
                // IP
                // =================================================

                if (ipAddress != '-') ...[
                  _divider(context),
                  _DeviceInfoRow(
                    icon: Icons.language_rounded,
                    label: 'IP Address',
                    value: ipAddress,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

/// ============================================================
/// DEVICE INFO ROW
/// ============================================================

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    final Color secondaryColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final Color valueColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // ICON
          // ======================================================

          SizedBox(
            width: 25,
            child: Icon(
              icon,
              size: 18,
              color: secondaryColor,
            ),
          ),

          const SizedBox(width: 7),

          // ======================================================
          // LABEL
          // ======================================================

          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // VALUE
          // ======================================================

          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// STATUS BADGE
/// ============================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String normalized = status.trim().toUpperCase();

    final bool isActive = normalized == 'ACTIVE';

    final bool isBlocked = normalized == 'BLOCKED' ||
        normalized == 'REVOKED' ||
        normalized == 'INACTIVE';

    late final Color background;
    late final Color foreground;

    if (isActive) {
      background = isDark ? const Color(0xFF12372A) : const Color(0xFFE8F8EF);

      foreground = isDark ? const Color(0xFF5EE0A0) : const Color(0xFF16834B);
    } else if (isBlocked) {
      background = isDark ? const Color(0xFF3B1D24) : const Color(0xFFFFE8EC);

      foreground = isDark ? const Color(0xFFFF8A9A) : const Color(0xFFD92D45);
    } else {
      background = isDark ? const Color(0xFF273244) : const Color(0xFFF3F4F6);

      foreground = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status == '-' ? 'Unknown' : _prettyText(status),
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// LOADING VIEW
/// ============================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading registered device...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// EMPTY DEVICE VIEW
/// ============================================================

class _EmptyDeviceView extends StatelessWidget {
  const _EmptyDeviceView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202B3D) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phonelink_erase_rounded,
              size: 34,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No Registered Device',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There is currently no mobile device '
            'registered for your account.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// ERROR VIEW
/// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3B1D24) : const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 34,
                color:
                    isDark ? const Color(0xFFFF8A9A) : const Color(0xFFE11D48),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load device',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// DIVIDER
/// ============================================================

Widget _divider(
  BuildContext context,
) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Divider(
    height: 1,
    thickness: 1,
    color: isDark ? const Color(0xFF263244) : const Color(0xFFF1F5F9),
  );
}

/// ============================================================
/// GET VALUE FROM API MAP
/// ============================================================

String _value(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final String key in keys) {
    final dynamic value = map[key];

    if (value == null) {
      continue;
    }

    final String text = value.toString().trim();

    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }

  return '-';
}

/// ============================================================
/// DEVICE ICON
/// ============================================================

IconData _deviceIcon(
  String platform,
) {
  final String value = platform.toLowerCase();

  if (value.contains('ios') || value.contains('iphone')) {
    return Icons.phone_iphone_rounded;
  }

  if (value.contains('android')) {
    return Icons.android_rounded;
  }

  if (value.contains('web')) {
    return Icons.language_rounded;
  }

  if (value.contains('windows') || value.contains('mac')) {
    return Icons.computer_rounded;
  }

  return Icons.smartphone_rounded;
}

/// ============================================================
/// DEVICE SUBTITLE
/// ============================================================

String _deviceSubtitle(
  String model,
  String platform,
) {
  if (model != '-' && platform != '-') {
    return '$model • ${_prettyText(platform)}';
  }

  if (model != '-') {
    return model;
  }

  if (platform != '-') {
    return _prettyText(platform);
  }

  return 'Registered mobile device';
}

/// ============================================================
/// PRETTY TEXT
/// ============================================================

String _prettyText(
  String value,
) {
  if (value == '-') {
    return value;
  }

  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where(
        (word) => word.trim().isNotEmpty,
      )
      .map(
    (word) {
      if (word.isEmpty) {
        return word;
      }

      if (word.length == 1) {
        return word.toUpperCase();
      }

      return '${word[0].toUpperCase()}'
          '${word.substring(1).toLowerCase()}';
    },
  ).join(' ');
}

/// ============================================================
/// FORMAT DATE TIME
/// ============================================================

String _formatDateTime(
  String value,
) {
  if (value == '-' || value.trim().isEmpty) {
    return '-';
  }

  try {
    final DateTime parsed = DateTime.parse(value);

    final DateTime date = parsed.isUtc ? parsed.toLocal() : parsed;

    final String day = date.day.toString().padLeft(
          2,
          '0',
        );

    final String month = date.month.toString().padLeft(
          2,
          '0',
        );

    final String year = date.year.toString();

    final int hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String hour = hour12.toString().padLeft(
          2,
          '0',
        );

    final String minute = date.minute.toString().padLeft(
          2,
          '0',
        );

    final String period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year  '
        '$hour:$minute $period';
  } catch (_) {
    return value;
  }
}
