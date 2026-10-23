import 'package:corehris/modules/HRMS/main_screens/subpages/controllers/view_profile_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Registered devices — Talexa minimalist Settings design.
/// Uses the existing ViewProfileController and its backend methods.
class DeviceLogScreen extends StatefulWidget {
  const DeviceLogScreen({super.key});

  @override
  State<DeviceLogScreen> createState() => _DeviceLogScreenState();
}

class _DeviceLogScreenState extends State<DeviceLogScreen> {
  static const _blue = Color(0xFF1769E8);
  static const _navy = Color(0xFF182237);
  static const _muted = Color(0xFF89919D);
  late final ViewProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ViewProfileController>()
        ? Get.find<ViewProfileController>()
        : Get.put(ViewProfileController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.fetchRegisteredDeviceInfo();
    });
  }

  Future<void> _reload() => controller.refreshDeviceInfo();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final ink = dark ? Colors.white : _navy;
    final secondary = dark ? Colors.white60 : _muted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Device Information',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Obx(() => IconButton(
                tooltip: 'Refresh devices',
                onPressed: controller.isDeviceLoading.value
                    ? null
                    : () => controller.fetchRegisteredDeviceInfo(),
                icon: controller.isDeviceLoading.value
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _blue),
                      )
                    : const Icon(Icons.refresh_rounded, size: 22),
              )),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final devices = controller.registeredDevices;
          final loading = controller.isDeviceLoading.value;
          final error = controller.deviceError.value;
          if (loading && devices.isEmpty) {
            return _StateView(
              icon: Icons.smartphone_outlined,
              title: 'Loading your devices',
              message: 'Retrieving registered device information.',
              loading: true,
              dark: dark,
            );
          }
          if (devices.isEmpty && error != null && error.trim().isNotEmpty) {
            return _StateView(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load devices',
              message: error,
              dark: dark,
              retry: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: _blue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                const SizedBox(height: 6),
                const Icon(Icons.phonelink_lock_outlined,
                    size: 37, color: _blue),
                const SizedBox(height: 15),
                Text('Your registered devices',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: ink, fontSize: 23, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text('Review devices associated with your Talexa account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: secondary, fontSize: 12.5, height: 1.5)),
                const SizedBox(height: 30),
                Row(children: [
                  Expanded(
                      child: Text('REGISTERED DEVICES',
                          style: TextStyle(
                              color: secondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .8))),
                  Text(
                      '${devices.length} ${devices.length == 1 ? 'device' : 'devices'}',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
                const SizedBox(height: 11),
                if (devices.isEmpty)
                  _EmptyCard(dark: dark)
                else
                  for (final device in devices) ...[
                    _DeviceCard(
                        device: Map<String, dynamic>.from(device), dark: dark),
                    const SizedBox(height: 13),
                  ],
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shield_outlined, size: 16, color: secondary),
                  const SizedBox(width: 7),
                  Flexible(
                      child: Text(
                          'Device information is linked to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: secondary))),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.dark});
  final Map<String, dynamic> device;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final line = dark ? Colors.white12 : const Color(0xFFECEFF3);
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final secondary = dark ? Colors.white60 : const Color(0xFF89919D);

    final name = _value(device, ['device_name', 'deviceName', 'name']);
    final model = _value(device, ['model', 'device_model', 'deviceModel']);
    final platform = _value(device, ['platform', 'os', 'operating_system']);
    final status = _value(device, ['status', 'device_status']);
    final details = <_InfoEntry>[
      _InfoEntry(Icons.fingerprint_rounded, 'Device ID',
          _value(device, ['device_id', 'deviceId', 'uuid', 'identifier'])),
      _InfoEntry(Icons.smartphone_outlined, 'Model', model),
      _InfoEntry(_platformIcon(platform), 'Platform', platform),
      _InfoEntry(Icons.info_outline_rounded, 'OS version',
          _value(device, ['os_version', 'osVersion'])),
      _InfoEntry(Icons.apps_outlined, 'App version',
          _value(device, ['app_version', 'appVersion'])),
      _InfoEntry(
          Icons.event_outlined,
          'Registered',
          _formatDateTime(_value(device,
              ['registered_at', 'registeredAt', 'created_at', 'createdAt']))),
      _InfoEntry(
          Icons.login_rounded,
          'Last login',
          _formatDateTime(_value(device,
              ['last_login_at', 'lastLoginAt', 'last_login', 'lastLogin']))),
      _InfoEntry(
          Icons.schedule_rounded,
          'Last seen',
          _formatDateTime(_value(device, [
            'last_seen_at',
            'lastSeenAt',
            'last_seen',
            'lastSeen',
            'updated_at'
          ]))),
      _InfoEntry(
          Icons.language_rounded,
          'IP address',
          _value(device, [
            'last_ip_address',
            'lastIpAddress',
            'ip_address',
            'ipAddress',
            'ip'
          ])),
    ];

    final visible = details.where((e) => e.value != '-').toList();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 19, 17, 19),
          child: Row(children: [
            Icon(_platformIcon(platform),
                color: dark ? const Color(0xFF8FBCFF) : const Color(0xFF1769E8),
                size: 27),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name == '-' ? 'Registered device' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_deviceSubtitle(model, platform),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 11.5)),
              ],
            )),
            const SizedBox(width: 8),
            _Status(status: status, dark: dark),
          ]),
        ),
        if (visible.isNotEmpty) ...[
          Divider(height: 1, thickness: 1, color: line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 2),
            child: Column(children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: line),
                _InfoRow(entry: visible[i], dark: dark),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

class _InfoEntry {
  const _InfoEntry(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.entry, required this.dark});
  final _InfoEntry entry;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? Colors.white : const Color(0xFF182237);
    final secondary = dark ? Colors.white60 : const Color(0xFF89919D);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(entry.icon, size: 19, color: secondary),
        const SizedBox(width: 12),
        Expanded(
            flex: 3,
            child: Text(entry.label,
                style: TextStyle(color: secondary, fontSize: 12.5))),
        const SizedBox(width: 10),
        Expanded(
            flex: 5,
            child: SelectableText(entry.value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35))),
      ]),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status, required this.dark});
  final String status;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final active = normalized == 'ACTIVE';
    final blocked = normalized == 'BLOCKED' ||
        normalized == 'REVOKED' ||
        normalized == 'INACTIVE';
    final color = active
        ? (dark ? const Color(0xFF69D8A5) : const Color(0xFF16834B))
        : blocked
            ? (dark ? const Color(0xFFFF8A9A) : const Color(0xFFD64550))
            : (dark ? Colors.white60 : const Color(0xFF89919D));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(status == '-' ? 'Unknown' : _prettyText(status),
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
          color: dark ? const Color(0xFF1B2638) : Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(Icons.phonelink_erase_outlined,
            color: dark ? Colors.white60 : const Color(0xFF89919D), size: 36),
        const SizedBox(height: 16),
        Text('No registered devices',
            style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF182237),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Text('No mobile devices are currently linked to your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: dark ? Colors.white60 : const Color(0xFF89919D),
                fontSize: 12.5,
                height: 1.5)),
      ]),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView(
      {required this.icon,
      required this.title,
      required this.message,
      required this.dark,
      this.retry,
      this.loading = false});
  final IconData icon;
  final String title;
  final String message;
  final bool dark;
  final Future<void> Function()? retry;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final secondary = dark ? Colors.white60 : const Color(0xFF89919D);
    return Center(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (loading)
          const CircularProgressIndicator(
              color: Color(0xFF1769E8), strokeWidth: 2.5)
        else
          Icon(icon, size: 42, color: const Color(0xFF1769E8)),
        const SizedBox(height: 19),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : const Color(0xFF182237))),
        const SizedBox(height: 9),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary, fontSize: 12.5, height: 1.5)),
        if (retry != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () => retry!(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1769E8),
                  foregroundColor: Colors.white),
              child: const Text('Try again')),
        ],
      ]),
    ));
  }
}

String _value(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '-';
}

IconData _platformIcon(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('ios') || p.contains('iphone'))
    return Icons.phone_iphone_rounded;
  if (p.contains('android')) return Icons.android_rounded;
  if (p.contains('web')) return Icons.language_rounded;
  if (p.contains('windows') || p.contains('mac')) return Icons.computer_rounded;
  return Icons.smartphone_rounded;
}

String _deviceSubtitle(String model, String platform) {
  if (model != '-' && platform != '-')
    return '$model • ${_prettyText(platform)}';
  if (model != '-') return model;
  if (platform != '-') return _prettyText(platform);
  return 'Registered mobile device';
}

String _prettyText(String value) {
  if (value == '-') return value;
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _formatDateTime(String value) {
  if (value == '-' || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final local = date.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}  '
      '${two(h)}:${two(local.minute)} $ampm';
}
