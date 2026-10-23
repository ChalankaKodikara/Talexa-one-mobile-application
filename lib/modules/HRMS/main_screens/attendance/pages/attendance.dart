// Talexa HRMS — full-screen attendance map layout.
// Replace the existing AttendancePage widget file with this source.
import 'dart:async';

import 'package:corehris/modules/HRMS/main_screens/attendance/controllers/attendance_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String username;
  const AttendancePage({super.key, required this.username});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  late final AttendanceController controller;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  static const _blue = Color(0xFF1769E8);
  static const _mint = Color(0xFF25E4BE);

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => _dark ? const Color(0xFF191C24) : Colors.white;
  Color get _page => _dark ? const Color(0xFF101319) : const Color(0xFFF6F8FC);
  Color get _text => _dark ? Colors.white : const Color(0xFF151B2B);
  Color get _muted => _dark ? const Color(0xFFA9AFBE) : const Color(0xFF748094);
  Color get _border =>
      _dark ? const Color(0xFF2C303A) : const Color(0xFFE7EBF3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<AttendanceController>()
        ? Get.find<AttendanceController>()
        : Get.put(AttendanceController(), permanent: true);
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = DateTime.now());
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    await Future.wait([
      controller.fetchAndShowLocation(),
      controller.fetchTodayAttendance(),
    ]);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Attendance',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh location and attendance',
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopSection(),
            // Map occupies all free vertical space, including the area that
            // previously appeared empty below the compact location card.
            Expanded(child: _buildMapArea()),
            _buildBottomPunchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      decoration: BoxDecoration(
        color: _page,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMMM yyyy').format(_now),
                          style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w800,
                              fontSize: 23,
                              letterSpacing: -0.7)),
                      const SizedBox(height: 2),
                      Text(DateFormat('EEEE, d MMMM yyyy').format(_now),
                          style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _border)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('hh:mm').format(_now),
                          style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1)),
                      Text(DateFormat('a').format(_now),
                          style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            _buildWeekStrip(),
            const SizedBox(height: 15),
            Row(children: [
              Text('Your Attendance',
                  style: TextStyle(
                      color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('Today',
                  style: TextStyle(
                      color: _blue, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            Obx(() => _buildAttendanceTiles()),
            const SizedBox(height: 12),
            Obx(() => _buildModeSelector()),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return Row(
      children: List.generate(7, (index) {
        final day = monday.add(Duration(days: index));
        final isToday = day == today;
        return Expanded(
          child: Column(
            children: [
              Text(DateFormat('EEE').format(day),
                  style: TextStyle(
                      color: isToday ? _text : _muted,
                      fontSize: 10.5,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500)),
              const SizedBox(height: 7),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: isToday ? _mint : Colors.transparent,
                    shape: BoxShape.circle),
                child: Text('${day.day}',
                    style: TextStyle(
                      color: isToday ? const Color(0xFF0C2730) : _text,
                      fontSize: 15,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                    )),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _hasTime(String value) =>
      value.trim().isNotEmpty && value != '--:--' && value != '--';

  Widget _buildAttendanceTiles() {
    if (controller.isLoadingAttendance.value) {
      return Container(
        height: 105,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(18)),
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    final inTime = controller.checkINTime.value;
    final outTime = controller.checkOutTime.value;
    return Row(children: [
      Expanded(
        child: _attendanceTile(
          label: 'Check In',
          time: _hasTime(inTime) ? inTime : 'Not Yet',
          status: controller.checkINType.value.isEmpty
              ? 'Pending'
              : controller.checkINType.value,
          icon: Icons.login_rounded,
          active: _hasTime(inTime),
          accent: const Color(0xFF16B68A),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _attendanceTile(
          label: 'Check Out',
          time: _hasTime(outTime) ? outTime : 'Not Yet',
          status: controller.checkOutType.value.isEmpty
              ? 'Pending'
              : controller.checkOutType.value,
          icon: Icons.logout_rounded,
          active: _hasTime(outTime),
          accent: const Color(0xFFE98B54),
        ),
      ),
    ]);
  }

  Widget _attendanceTile({
    required String label,
    required String time,
    required String status,
    required IconData icon,
    required bool active,
    required Color accent,
  }) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accent, size: 17),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _muted, fontSize: 11))),
            Icon(active ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: active ? accent : _muted, size: 12),
          ]),
          const Spacer(),
          Text(time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: active ? _text : _muted,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.65)),
          const SizedBox(height: 3),
          Text(status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _muted, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(children: [
      Expanded(
        child: _modeButton(
            AttendanceWorkMode.onSite, Icons.business_outlined, 'On-site'),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _modeButton(AttendanceWorkMode.workFromHome,
            Icons.route_outlined, 'Outside / Field'),
      ),
    ]);
  }

  Widget _modeButton(AttendanceWorkMode mode, IconData icon, String title) {
    final selected = controller.selectedWorkMode.value == mode;
    return Material(
      color: selected
          ? (_dark ? const Color(0xFF223C68) : const Color(0xFFE9F2FF))
          : _surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.selectWorkMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 41,
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? _blue : _border, width: selected ? 1.4 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? _blue : _muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: selected ? (_dark ? Colors.white : _blue) : _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    return Obx(() {
      final pos = controller.currentPosition.value;
      final isOutside = controller.requiresOfficeRadius &&
          !controller.isInsideOfficeRadius.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: controller.currentLatLng.value ??
                  AttendanceController.fallbackCenter,
              zoom: 16.5,
            ),
            markers: controller.mapMarkers,
            circles: controller.mapCircles,
            onMapCreated: controller.onMapCreated,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          Positioned(
            top: 13,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_dark ? 0.24 : 0.11),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(children: [
                const Icon(Icons.my_location_rounded, color: _blue, size: 17),
                const SizedBox(width: 9),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Location',
                        style: TextStyle(
                            color: _text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        controller.currentAddress.value.isEmpty
                            ? 'Finding your location…'
                            : controller.currentAddress.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _muted, fontSize: 10.5)),
                  ],
                )),
                if (pos != null)
                  Text('±${pos.accuracy.toStringAsFixed(0)}m',
                      style: TextStyle(color: _muted, fontSize: 10)),
                const SizedBox(width: 3),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Update GPS',
                  onPressed: controller.isFetchingLocation.value
                      ? null
                      : controller.fetchAndShowLocation,
                  icon: controller.isFetchingLocation.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.refresh_rounded, size: 19, color: _blue),
                ),
              ]),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.13), blurRadius: 12)
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(
                      isOutside
                          ? Icons.info_outline_rounded
                          : Icons.verified_rounded,
                      size: 17,
                      color: isOutside
                          ? const Color(0xFFE39B33)
                          : const Color(0xFF11B78B)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(controller.radiusStatusText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                ]),
                if (pos?.isMocked ?? false) ...[
                  const SizedBox(height: 7),
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFE35A55)),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(
                            'Mock location detected. Reported to server.',
                            style: TextStyle(color: _muted, fontSize: 10.5))),
                  ]),
                ],
              ]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomPunchBar() {
    return Obx(() {
      final canSubmit = controller.canSubmitAttendance;
      final busy = controller.isSubmittingAttendance.value ||
          controller.isButtonDisabled.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _surface,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('MARK ATTENDANCE',
                style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const Spacer(),
            Flexible(
                child: Text(
              '${controller.selectedWorkMode.value.label} · ${controller.nextAttendanceAction}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _muted, fontSize: 10.5),
            )),
          ]),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: ElevatedButton.icon(
              onPressed: canSubmit && !busy
                  ? () async {
                      controller.isButtonDisabled.value = true;
                      try {
                        await controller.openConfirmLocationSheet();
                      } finally {
                        controller.isButtonDisabled.value = false;
                      }
                    }
                  : null,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF162130)))
                  : const Icon(Icons.fingerprint_rounded, size: 21),
              label: Text(busy ? 'Processing…' : 'Punch Attendance',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD949),
                foregroundColor: const Color(0xFF182234),
                disabledBackgroundColor:
                    _dark ? const Color(0xFF665C39) : const Color(0xFFFFEAA1),
                disabledForegroundColor:
                    _dark ? Colors.white60 : const Color(0xFF80755C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]),
      );
    });
  }
}
