// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/utils/api_error_handler.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceWorkMode {
  onSite,
  workFromHome,
}

extension AttendanceWorkModeExtension on AttendanceWorkMode {
  String get apiValue {
    switch (this) {
      case AttendanceWorkMode.onSite:
        return 'OFFICE';

      case AttendanceWorkMode.workFromHome:
        return 'WFH';
    }
  }

  String get label {
    switch (this) {
      case AttendanceWorkMode.onSite:
        return 'On-site';

      case AttendanceWorkMode.workFromHome:
        return 'Work From OutSide';
    }
  }
}

// ============================================================================
// AUTHORIZED ATTENDANCE LOCATION
// ============================================================================

class AuthorizedAttendanceLocation {
  final dynamic id;
  final dynamic attendanceLocationId;

  final String locationName;
  final String locationType;

  final String? areaAlias;
  final String? terminalAlias;
  final String? terminalSn;

  final double latitude;
  final double longitude;

  final String? address;

  final double allowedRadiusMeters;

  final bool requiresApproval;

  final dynamic validFrom;
  final dynamic validTo;

  final String source;

  const AuthorizedAttendanceLocation({
    required this.id,
    required this.attendanceLocationId,
    required this.locationName,
    required this.locationType,
    required this.areaAlias,
    required this.terminalAlias,
    required this.terminalSn,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.allowedRadiusMeters,
    required this.requiresApproval,
    required this.validFrom,
    required this.validTo,
    required this.source,
  });

  LatLng get latLng {
    return LatLng(
      latitude,
      longitude,
    );
  }

  bool get isCompanyLocation {
    return source.toUpperCase() == 'COMPANY';
  }

  bool get isEmployeeAuthorizedLocation {
    return source.toUpperCase() == 'EMPLOYEE_AUTHORIZED';
  }

  factory AuthorizedAttendanceLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    double parseDouble(
      dynamic value, {
      double fallback = 0,
    }) {
      if (value == null) {
        return fallback;
      }

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value.toString().trim(),
          ) ??
          fallback;
    }

    bool parseBool(
      dynamic value,
    ) {
      if (value == null) {
        return false;
      }

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final text = value.toString().trim().toLowerCase();

      return text == 'true' || text == '1' || text == 'yes';
    }

    String parseString(
      dynamic value, {
      String fallback = '',
    }) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty || text.toLowerCase() == 'null') {
        return fallback;
      }

      return text;
    }

    String? parseNullableString(
      dynamic value,
    ) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty || text.toLowerCase() == 'null') {
        return null;
      }

      return text;
    }

    return AuthorizedAttendanceLocation(
      id: map['id'],
      attendanceLocationId: map['attendance_location_id'],
      locationName: parseString(
        map['location_name'],
        fallback: 'Authorized Location',
      ),
      locationType: parseString(
        map['location_type'],
        fallback: 'OTHER',
      ),
      areaAlias: parseNullableString(
        map['area_alias'],
      ),
      terminalAlias: parseNullableString(
        map['terminal_alias'],
      ),
      terminalSn: parseNullableString(
        map['terminal_sn'],
      ),
      latitude: parseDouble(
        map['latitude'],
      ),
      longitude: parseDouble(
        map['longitude'],
      ),
      address: parseNullableString(
        map['address'],
      ),
      allowedRadiusMeters: parseDouble(
        map['allowed_radius_meters'],
        fallback: 100,
      ),
      requiresApproval: parseBool(
        map['requires_approval'],
      ),
      validFrom: map['valid_from'],
      validTo: map['valid_to'],
      source: parseString(
        map['source'],
        fallback: 'EMPLOYEE_AUTHORIZED',
      ),
    );
  }
}

// ============================================================================
// ATTENDANCE PUNCH
// ============================================================================

class _AttendancePunch {
  final String action;
  final String displayTime;
  final String type;
  final DateTime dateTime;

  const _AttendancePunch({
    required this.action,
    required this.displayTime,
    required this.type,
    required this.dateTime,
  });
}

// ============================================================================
// CONTROLLER
// ============================================================================

class AttendanceController extends GetxController {
  final AuthService authService = AuthService();

  // ===========================================================================
  // MAP
  // ===========================================================================

  GoogleMapController? googleMapController;

  StreamSubscription<Position>? positionStream;

  Timer? _cameraDebounce;
  Timer? _addressDebounce;

  bool mapReady = false;

  final currentLatLng = Rxn<LatLng>();
  final currentPosition = Rxn<Position>();

  // ===========================================================================
  // EMPLOYEE
  // ===========================================================================

  final employeeID = ''.obs;

  // ===========================================================================
  // AUTHORIZED LOCATIONS
  // ===========================================================================

  final authorizedLocations = <AuthorizedAttendanceLocation>[].obs;

  final isLoadingAuthorizedLocations = false.obs;

  final authorizedLocationError = ''.obs;

  final selectedAuthorizedLocation = Rxn<AuthorizedAttendanceLocation>();

  /// Nearest authorized location regardless of whether
  /// the user is inside its radius.
  final nearestAuthorizedLocation = Rxn<AuthorizedAttendanceLocation>();

  /// Distance from current user position to the nearest
  /// authorized attendance location.
  final distanceFromOfficeMeters = RxnDouble();

  /// True when current position is inside at least one
  /// authorized attendance location radius.
  final isInsideOfficeRadius = false.obs;

  /// Maximum allowed GPS accuracy returned from backend.
  final maxGpsAccuracyMeters = 100.0.obs;

  final companyLocationAvailable = false.obs;

  final employeeAuthorizedLocationCount = 0.obs;

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  final currentAddress = ''.obs;

  final selectedWorkMode = AttendanceWorkMode.onSite.obs;

  // ===========================================================================
  // DEVICE / APPLICATION METADATA
  // ===========================================================================

  final deviceId = ''.obs;
  final deviceName = ''.obs;
  final deviceOS = ''.obs;
  final appVersion = ''.obs;

  // ===========================================================================
  // OPTIONAL ATTENDANCE EVIDENCE
  // ===========================================================================

  final reason = RxnString();
  final photoUrl = RxnString();
  final documentUrl = RxnString();

  // ===========================================================================
  // TODAY'S DISPLAY DATA
  // ===========================================================================

  final checkINTime = ''.obs;
  final checkOutTime = ''.obs;

  final checkINType = ''.obs;
  final checkOutType = ''.obs;

  final latestPunchAction = 'CHECK_OUT'.obs;

  // ===========================================================================
  // LOADING STATES
  // ===========================================================================

  final isInitializing = false.obs;
  final isFetchingLocation = false.obs;
  final isFetchingAddress = false.obs;
  final isLoadingAttendance = false.obs;
  final isSubmittingAttendance = false.obs;

  final isButtonDisabled = false.obs;

  final locationError = ''.obs;

  // ===========================================================================
  // FALLBACK MAP LOCATION
  // ===========================================================================

  static const LatLng fallbackCenter = LatLng(
    6.9220294,
    79.8674413,
  );

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void onInit() {
    super.onInit();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (isInitializing.value) {
      return;
    }

    isInitializing.value = true;

    try {
      await _loadUser();

      if (employeeID.value.isEmpty) {
        locationError.value = 'Employee number was not found.';

        return;
      }

      await _loadDeviceMetadata();

      /// Load authorized locations before GPS validation.
      await fetchAuthorizedLocations();

      await Future.wait([
        _initLocation(),
        fetchTodayAttendance(),
      ]);
    } catch (error, stackTrace) {
      print(
        '❌ Attendance bootstrap error: $error',
      );

      print(
        stackTrace,
      );

      locationError.value =
          'Unable to initialize attendance. Please try again.';
    } finally {
      isInitializing.value = false;
    }
  }

  // ===========================================================================
  // EMPLOYEE
  // ===========================================================================

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      employeeID.value = (prefs.getString(
                'employee_no',
              ) ??
              prefs.getString(
                'employee_id',
              ) ??
              '')
          .trim();

      print(
        '✅ Attendance employee number: ${employeeID.value}',
      );
    } catch (error) {
      print(
        '❌ Load employee error: $error',
      );

      employeeID.value = '';
    }
  }

  // ===========================================================================
  // LOAD AUTHORIZED LOCATIONS
  // ===========================================================================

  Future<void> fetchAuthorizedLocations() async {
    if (isLoadingAuthorizedLocations.value) {
      return;
    }

    final employeeNo = employeeID.value.trim();

    if (employeeNo.isEmpty) {
      authorizedLocations.clear();

      authorizedLocationError.value = 'Employee number is unavailable.';

      return;
    }

    isLoadingAuthorizedLocations.value = true;

    authorizedLocationError.value = '';

    try {
      print(
        '📍 Loading authorized locations for $employeeNo...',
      );

      final Map<String, dynamic> response =
          await authService.attendance.fetchAuthorizedLocations(
        employeeId: employeeNo,
      );

      final dynamic rawData = response['data'];

      if (rawData is! Map) {
        throw Exception(
          'Authorized location data was not returned by the server.',
        );
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        rawData,
      );

      // -----------------------------------------------------------------------
      // GPS RULES
      // -----------------------------------------------------------------------

      final dynamic rawGpsRules = data['gps_rules'];

      if (rawGpsRules is Map) {
        final Map<String, dynamic> gpsRules = Map<String, dynamic>.from(
          rawGpsRules,
        );

        maxGpsAccuracyMeters.value = _toDouble(
              gpsRules['max_accuracy_meters'],
            ) ??
            100;
      } else {
        maxGpsAccuracyMeters.value = 100;
      }

      // -----------------------------------------------------------------------
      // OTHER INFO
      // -----------------------------------------------------------------------

      companyLocationAvailable.value = _toBool(
        data['company_location_available'],
      );

      employeeAuthorizedLocationCount.value = _toInt(
            data['employee_location_count'],
          ) ??
          0;

      // -----------------------------------------------------------------------
      // LOCATIONS
      // -----------------------------------------------------------------------

      final List<AuthorizedAttendanceLocation> loadedLocations = [];

      final dynamic rawLocations = data['locations'];

      if (rawLocations is List) {
        for (final dynamic rawLocation in rawLocations) {
          if (rawLocation is! Map) {
            continue;
          }

          final map = Map<String, dynamic>.from(
            rawLocation,
          );

          final latitude = _toDouble(
            map['latitude'],
          );

          final longitude = _toDouble(
            map['longitude'],
          );

          if (latitude == null || longitude == null) {
            continue;
          }

          if (!_isValidLatitude(
                latitude,
              ) ||
              !_isValidLongitude(
                longitude,
              )) {
            continue;
          }

          loadedLocations.add(
            AuthorizedAttendanceLocation.fromMap(
              map,
            ),
          );
        }
      }

      authorizedLocations.assignAll(
        loadedLocations,
      );

      print(
        '✅ Authorized locations loaded: '
        '${authorizedLocations.length}',
      );

      print(
        '📍 Max GPS accuracy: '
        '${maxGpsAccuracyMeters.value}m',
      );

      for (final location in authorizedLocations) {
        print(
          '📍 ${location.locationName} '
          '[${location.source}] '
          '${location.latitude}, '
          '${location.longitude} '
          'radius=${location.allowedRadiusMeters}m',
        );
      }

      if (authorizedLocations.isEmpty) {
        authorizedLocationError.value =
            'No authorized attendance locations are assigned to this employee.';
      }

      _calculateOfficeDistance();
    } catch (error, stackTrace) {
      print(
        '❌ Authorized locations error: $error',
      );

      print(
        stackTrace,
      );

      authorizedLocations.clear();

      selectedAuthorizedLocation.value = null;

      nearestAuthorizedLocation.value = null;

      isInsideOfficeRadius.value = false;

      distanceFromOfficeMeters.value = null;

      authorizedLocationError.value = _attendanceErrorMessage(
        error,
      );
    } finally {
      isLoadingAuthorizedLocations.value = false;
    }
  }

  // ===========================================================================
  // DEVICE METADATA
  // ===========================================================================

  Future<void> _loadDeviceMetadata() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;

        deviceName.value = _joinNonEmpty([
          androidInfo.manufacturer,
          androidInfo.model,
        ]);

        deviceOS.value = 'Android ${androidInfo.version.release}';

        final hardwareId = androidInfo.id.trim();

        if (hardwareId.isNotEmpty) {
          deviceId.value = hardwareId;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;

        deviceName.value = iosInfo.name.trim().isNotEmpty
            ? iosInfo.name.trim()
            : iosInfo.model.trim();

        deviceOS.value = '${iosInfo.systemName} '
                '${iosInfo.systemVersion}'
            .trim();

        final vendorId = iosInfo.identifierForVendor?.trim() ?? '';

        if (vendorId.isNotEmpty) {
          deviceId.value = vendorId;
        }
      } else {
        deviceName.value = Platform.localHostname;

        deviceOS.value = Platform.operatingSystem;
      }
    } catch (error) {
      print(
        '⚠️ Device information error: $error',
      );
    }

    if (deviceId.value.trim().isEmpty) {
      deviceId.value = await _getOrCreateInstallationId();
    }

    if (deviceName.value.trim().isEmpty) {
      deviceName.value = 'Unknown Device';
    }

    if (deviceOS.value.trim().isEmpty) {
      deviceOS.value = Platform.operatingSystem;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      appVersion.value = packageInfo.version.trim();

      if (appVersion.value.isEmpty) {
        appVersion.value = 'Unknown';
      }
    } catch (error) {
      print(
        '⚠️ App version error: $error',
      );

      appVersion.value = 'Unknown';
    }

    print(
      '📱 Device ID: ${deviceId.value}',
    );

    print(
      '📱 Device Name: ${deviceName.value}',
    );

    print(
      '📱 Device OS: ${deviceOS.value}',
    );

    print(
      '📱 App Version: ${appVersion.value}',
    );
  }

  Future<String> _getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();

    const storageKey = 'attendance_device_installation_id';

    final existingId = prefs
        .getString(
          storageKey,
        )
        ?.trim();

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final generatedId = _generateInstallationId();

    await prefs.setString(
      storageKey,
      generatedId,
    );

    return generatedId;
  }

  String _generateInstallationId() {
    final random = Random.secure();

    String randomPart(
      int length,
    ) {
      const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

      return List.generate(
        length,
        (_) => characters[random.nextInt(
          characters.length,
        )],
      ).join();
    }

    return 'MOBILE-${randomPart(6)}-'
        '${DateTime.now().millisecondsSinceEpoch}-'
        '${randomPart(6)}';
  }

  String _joinNonEmpty(
    List<String> values,
  ) {
    return values
        .map(
          (value) => value.trim(),
        )
        .where(
          (value) => value.isNotEmpty,
        )
        .join(
          ' ',
        );
  }

  // ===========================================================================
  // WORK MODE
  // ===========================================================================

  void selectWorkMode(
    AttendanceWorkMode mode,
  ) {
    selectedWorkMode.value = mode;

    _calculateOfficeDistance();

    safeAnimateCamera();
  }

  bool get requiresOfficeRadius {
    return selectedWorkMode.value == AttendanceWorkMode.onSite;
  }

  // ===========================================================================
  // AUTHORIZED LOCATION HELPERS
  // ===========================================================================

  String get authorizedLocationName {
    final location =
        selectedAuthorizedLocation.value ?? nearestAuthorizedLocation.value;

    if (location == null) {
      return '';
    }

    return location.locationName;
  }

  String get authorizedLocationAddress {
    final location =
        selectedAuthorizedLocation.value ?? nearestAuthorizedLocation.value;

    if (location == null) {
      return '';
    }

    return location.address ?? location.locationName;
  }

  double? get authorizedLocationRadius {
    final location =
        selectedAuthorizedLocation.value ?? nearestAuthorizedLocation.value;

    return location?.allowedRadiusMeters;
  }

  String get radiusStatusText {
    if (!requiresOfficeRadius) {
      return 'Work From Outside selected. '
          'Your current GPS location will be submitted.';
    }

    if (isLoadingAuthorizedLocations.value) {
      return 'Loading authorized attendance locations...';
    }

    if (authorizedLocations.isEmpty) {
      return authorizedLocationError.value.trim().isNotEmpty
          ? authorizedLocationError.value
          : 'No authorized On-site attendance location is available.';
    }

    final distance = distanceFromOfficeMeters.value;

    final selected = selectedAuthorizedLocation.value;

    final nearest = nearestAuthorizedLocation.value;

    if (distance == null) {
      return 'Calculating distance from your authorized location...';
    }

    if (isInsideOfficeRadius.value && selected != null) {
      return 'You are inside ${selected.locationName} '
          '(${distance.toStringAsFixed(1)}m away, '
          'allowed ${selected.allowedRadiusMeters.toStringAsFixed(0)}m).';
    }

    if (nearest != null) {
      return 'You are ${distance.toStringAsFixed(1)}m from '
          '${nearest.locationName}. '
          'Allowed radius is '
          '${nearest.allowedRadiusMeters.toStringAsFixed(0)}m.';
    }

    return 'Your current location is outside all authorized On-site locations.';
  }

  // ===========================================================================
  // LOCATION PERMISSION
  // ===========================================================================

  Future<bool> _prepareLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        currentAddress.value = 'Location service is OFF. Please enable GPS.';

        locationError.value = 'Location service is disabled.';

        currentLatLng.value ??= fallbackCenter;

        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        currentAddress.value = 'Location permission was denied.';

        locationError.value =
            'Location permission is required to mark attendance.';

        currentLatLng.value ??= fallbackCenter;

        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        currentAddress.value = 'Location permission is permanently denied. '
            'Enable it from application settings.';

        locationError.value = 'Location permission is permanently denied.';

        currentLatLng.value ??= fallbackCenter;

        return false;
      }

      locationError.value = '';

      return true;
    } catch (error) {
      print(
        '❌ Location permission error: $error',
      );

      currentAddress.value = 'Unable to check location permission.';

      locationError.value = 'Unable to check location permission.';

      currentLatLng.value ??= fallbackCenter;

      return false;
    }
  }

  Future<void> _initLocation() async {
    final permissionReady = await _prepareLocationPermission();

    if (!permissionReady) {
      return;
    }

    await fetchAndShowLocation();

    await positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handlePositionUpdate,
      onError: (
        Object error,
      ) {
        print(
          '❌ Position stream error: $error',
        );

        locationError.value = 'Unable to continuously update your location.';
      },
      cancelOnError: false,
    );
  }

  void _handlePositionUpdate(
    Position position,
  ) {
    currentPosition.value = position;

    currentLatLng.value = LatLng(
      position.latitude,
      position.longitude,
    );

    _calculateOfficeDistance();

    safeAnimateCamera();

    _addressDebounce?.cancel();

    _addressDebounce = Timer(
      const Duration(
        milliseconds: 900,
      ),
      () {
        _updateAddress(
          position.latitude,
          position.longitude,
        );
      },
    );
  }

  // ===========================================================================
  // AUTHORIZED ON-SITE DISTANCE CALCULATION
  // ===========================================================================

  void _calculateOfficeDistance() {
    final position = currentPosition.value;

    if (position == null || authorizedLocations.isEmpty) {
      distanceFromOfficeMeters.value = null;

      isInsideOfficeRadius.value = false;

      selectedAuthorizedLocation.value = null;

      nearestAuthorizedLocation.value = null;

      return;
    }

    AuthorizedAttendanceLocation? nearestLocation;

    double? nearestDistance;

    AuthorizedAttendanceLocation? nearestValidLocation;

    double? nearestValidDistance;

    for (final location in authorizedLocations) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );

      print(
        '📍 Distance to '
        '${location.locationName}: '
        '${distance.toStringAsFixed(2)}m '
        '(allowed '
        '${location.allowedRadiusMeters.toStringAsFixed(0)}m)',
      );

      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;

        nearestLocation = location;
      }

      final isInside = distance <= location.allowedRadiusMeters;

      if (isInside) {
        if (nearestValidDistance == null || distance < nearestValidDistance) {
          nearestValidDistance = distance;

          nearestValidLocation = location;
        }
      }
    }

    nearestAuthorizedLocation.value = nearestLocation;

    if (nearestValidLocation != null && nearestValidDistance != null) {
      selectedAuthorizedLocation.value = nearestValidLocation;

      distanceFromOfficeMeters.value = nearestValidDistance;

      isInsideOfficeRadius.value = true;

      print(
        '✅ Inside authorized On-site location: '
        '${nearestValidLocation.locationName}',
      );

      print(
        '✅ Distance: '
        '${nearestValidDistance.toStringAsFixed(2)}m',
      );
    } else {
      selectedAuthorizedLocation.value = null;

      distanceFromOfficeMeters.value = nearestDistance;

      isInsideOfficeRadius.value = false;

      print(
        '❌ Outside all authorized On-site locations.',
      );

      if (nearestLocation != null && nearestDistance != null) {
        print(
          '📍 Nearest location: '
          '${nearestLocation.locationName}',
        );

        print(
          '📍 Distance: '
          '${nearestDistance.toStringAsFixed(2)}m',
        );
      }
    }
  }

  // ===========================================================================
  // FETCH LOCATION
  // ===========================================================================

  Future<void> fetchAndShowLocation() async {
    if (isFetchingLocation.value) {
      return;
    }

    isFetchingLocation.value = true;

    locationError.value = '';

    try {
      currentAddress.value = 'Fetching your current location...';

      final position = await _getFreshPosition();

      if (position == null) {
        throw Exception(
          'Unable to obtain location.',
        );
      }
    } catch (error, stackTrace) {
      print(
        '❌ Fetch location error: $error',
      );

      print(
        stackTrace,
      );

      currentLatLng.value ??= fallbackCenter;

      currentAddress.value = 'Unable to get the current location.';

      locationError.value = 'Move to an open area, enable GPS and try again.';
    } finally {
      isFetchingLocation.value = false;
    }
  }

  Future<Position?> _getFreshPosition() async {
    final permissionReady = await _prepareLocationPermission();

    if (!permissionReady) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(
            seconds: 20,
          ),
        ),
      );

      _handlePositionUpdate(
        position,
      );

      await _updateAddress(
        position.latitude,
        position.longitude,
      );

      return position;
    } on TimeoutException {
      print(
        '⚠️ Fresh location request timed out.',
      );

      final lastKnownPosition = await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null) {
        _handlePositionUpdate(
          lastKnownPosition,
        );

        await _updateAddress(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
      }

      return lastKnownPosition;
    } catch (error) {
      print(
        '❌ Fresh location error: $error',
      );

      return null;
    }
  }

  // ===========================================================================
  // ADDRESS
  // ===========================================================================

  Future<void> _updateAddress(
    double latitude,
    double longitude,
  ) async {
    if (isFetchingAddress.value) {
      return;
    }

    isFetchingAddress.value = true;

    try {
      currentAddress.value = 'Fetching address...';

      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        currentAddress.value = _coordinateFallbackAddress(
          latitude,
          longitude,
        );

        return;
      }

      final placemark = placemarks.first;

      final rawParts = <String>[
        (placemark.name ?? '').trim(),
        (placemark.street ?? '').trim(),
        (placemark.subLocality ?? '').trim(),
        (placemark.locality ?? '').trim(),
        (placemark.subAdministrativeArea ?? '').trim(),
        (placemark.administrativeArea ?? '').trim(),
        (placemark.postalCode ?? '').trim(),
        (placemark.country ?? '').trim(),
      ];

      final uniqueParts = <String>[];

      for (final part in rawParts) {
        if (part.isEmpty) {
          continue;
        }

        final alreadyExists = uniqueParts.any(
          (
            existingPart,
          ) =>
              existingPart.toLowerCase() == part.toLowerCase(),
        );

        if (!alreadyExists) {
          uniqueParts.add(
            part,
          );
        }
      }

      currentAddress.value = uniqueParts.isEmpty
          ? _coordinateFallbackAddress(
              latitude,
              longitude,
            )
          : uniqueParts.join(
              ', ',
            );

      print(
        '📍 Current address: ${currentAddress.value}',
      );
    } catch (error) {
      print(
        '❌ Address lookup error: $error',
      );

      currentAddress.value = _coordinateFallbackAddress(
        latitude,
        longitude,
      );
    } finally {
      isFetchingAddress.value = false;
    }
  }

  String _coordinateFallbackAddress(
    double latitude,
    double longitude,
  ) {
    return 'Latitude: '
        '${latitude.toStringAsFixed(6)}, '
        'Longitude: '
        '${longitude.toStringAsFixed(6)}';
  }

  // ===========================================================================
  // GOOGLE MAP
  // ===========================================================================

  void onMapCreated(
    GoogleMapController controller,
  ) {
    googleMapController = controller;

    mapReady = true;

    Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
      safeAnimateCamera,
    );
  }

  void safeAnimateCamera() {
    _cameraDebounce?.cancel();

    _cameraDebounce = Timer(
      const Duration(
        milliseconds: 250,
      ),
      () async {
        if (!mapReady || googleMapController == null) {
          return;
        }

        final target = currentLatLng.value;

        if (target == null) {
          return;
        }

        try {
          await googleMapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: target,
                zoom: 17,
              ),
            ),
          );
        } catch (error) {
          print(
            '❌ Animate camera error: $error',
          );
        }
      },
    );
  }

  // ===========================================================================
  // MAP MARKERS
  // ===========================================================================

  Set<Marker> get mapMarkers {
    final markers = <Marker>{};

    final employeeLocation = currentLatLng.value;

    if (employeeLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'current-location',
          ),
          position: employeeLocation,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: currentAddress.value,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (requiresOfficeRadius) {
      for (int index = 0; index < authorizedLocations.length; index++) {
        final location = authorizedLocations[index];

        markers.add(
          Marker(
            markerId: MarkerId(
              'authorized-${location.id ?? index}',
            ),
            position: location.latLng,
            infoWindow: InfoWindow(
              title: location.locationName,
              snippet: '${location.source} • '
                  '${location.allowedRadiusMeters.toStringAsFixed(0)}m radius',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              location.isCompanyLocation
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    return markers;
  }

  // ===========================================================================
  // MAP CIRCLES
  // ===========================================================================

  Set<Circle> get mapCircles {
    if (!requiresOfficeRadius) {
      return <Circle>{};
    }

    final circles = <Circle>{};

    for (int index = 0; index < authorizedLocations.length; index++) {
      final location = authorizedLocations[index];

      circles.add(
        Circle(
          circleId: CircleId(
            'authorized-radius-${location.id ?? index}',
          ),
          center: location.latLng,
          radius: location.allowedRadiusMeters,
          fillColor: Colors.blue.withValues(
            alpha: 0.12,
          ),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  // ===========================================================================
  // ATTENDANCE UI STATE
  // ===========================================================================

  bool get hasCheckedIn {
    return checkINTime.value.trim().isNotEmpty;
  }

  bool get hasCheckedOut {
    return checkOutTime.value.trim().isNotEmpty;
  }

  /// Multiple punches continue to be allowed.
  bool get attendanceCompleted => false;

  String get nextAttendanceAction {
    if (!hasCheckedIn && !hasCheckedOut) {
      return 'Check In';
    }

    return latestPunchAction.value == 'CHECK_IN' ? 'Check Out' : 'Check In';
  }

  String get apiPunchType => 'UNKNOWN';

  bool get canSubmitAttendance {
    if (employeeID.value.trim().isEmpty) {
      return false;
    }

    if (isSubmittingAttendance.value) {
      return false;
    }

    if (isFetchingLocation.value) {
      return false;
    }

    if (isButtonDisabled.value) {
      return false;
    }

    return true;
  }

  // ===========================================================================
  // CONFIRM ATTENDANCE
  // ===========================================================================

  Future<void> openConfirmLocationSheet() async {
    if (isSubmittingAttendance.value) {
      return;
    }

    if (employeeID.value.trim().isEmpty) {
      _showAlert(
        AppAlertType.error,
        'Employee Not Found',
        'Employee number is unavailable. '
            'Please log in again.',
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Make sure authorized locations have loaded for On-site.
    // -------------------------------------------------------------------------

    if (selectedWorkMode.value == AttendanceWorkMode.onSite &&
        authorizedLocations.isEmpty) {
      await fetchAuthorizedLocations();

      if (authorizedLocations.isEmpty) {
        _showAlert(
          AppAlertType.warning,
          'No Authorized Location',
          authorizedLocationError.value.trim().isNotEmpty
              ? authorizedLocationError.value
              : 'No authorized On-site attendance location is assigned to you.',
        );

        return;
      }
    }

    final position = await _getFreshPosition();

    if (position == null) {
      _showAlert(
        AppAlertType.warning,
        'Location Unavailable',
        'Unable to obtain your current location. '
            'Enable GPS and try again.',
      );

      return;
    }

    print(
      '📍 GPS accuracy: ${position.accuracy} meters',
    );

    print(
      '📍 Allowed GPS accuracy: ${maxGpsAccuracyMeters.value} meters',
    );

    print(
      '📍 Mock location: ${position.isMocked}',
    );

    _calculateOfficeDistance();

    // -------------------------------------------------------------------------
    // ON-SITE VALIDATION
    // -------------------------------------------------------------------------

    if (selectedWorkMode.value == AttendanceWorkMode.onSite) {
      if (!isInsideOfficeRadius.value ||
          selectedAuthorizedLocation.value == null) {
        final nearest = nearestAuthorizedLocation.value;

        final distance = distanceFromOfficeMeters.value;

        String message =
            'Your current location is outside all authorized On-site attendance locations.';

        if (nearest != null && distance != null) {
          message =
              'Your current location is not inside an authorized On-site location.\n\n'
              'Nearest: ${nearest.locationName}\n'
              'Distance: ${distance.toStringAsFixed(1)} meters\n'
              'Allowed radius: ${nearest.allowedRadiusMeters.toStringAsFixed(0)} meters';
        }

        _showAlert(
          AppAlertType.warning,
          'Outside Authorized Location',
          message,
        );

        return;
      }
    }

    final context = Get.context;

    if (context == null) {
      return;
    }

    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(
              24,
            ),
          ),
          border: Border.all(
            color: theme.dividerColor.withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(
                    999,
                  ),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                'Confirm Attendance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Expected: $nextAttendanceAction',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(
                height: 8,
              ),
              Obx(
                () => Text(
                  selectedWorkMode.value.label,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Obx(
                () {
                  if (selectedWorkMode.value != AttendanceWorkMode.onSite) {
                    return const SizedBox.shrink();
                  }

                  final location = selectedAuthorizedLocation.value;

                  if (location == null) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          location.locationName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (location.address != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                            ),
                            child: Text(
                              location.address!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Allowed radius: '
                          '${location.allowedRadiusMeters.toStringAsFixed(0)}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 14,
              ),
              Obx(
                () {
                  final latLng = currentLatLng.value ?? fallbackCenter;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                    child: SizedBox(
                      height: 210,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: latLng,
                          zoom: 17,
                        ),
                        markers: mapMarkers,
                        circles: mapCircles,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 14,
              ),
              Obx(
                () => Text(
                  currentAddress.value.isEmpty
                      ? 'Fetching address...'
                      : currentAddress.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Obx(
                () => Text(
                  radiusStatusText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isInsideOfficeRadius.value ||
                            selectedWorkMode.value ==
                                AttendanceWorkMode.workFromHome
                        ? Colors.green
                        : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Obx(
                () {
                  final position = currentPosition.value;

                  if (position == null) {
                    return const SizedBox.shrink();
                  }

                  final accuracyOkay =
                      position.accuracy <= maxGpsAccuracyMeters.value;

                  return Column(
                    children: [
                      Text(
                        'GPS accuracy: '
                        '${position.accuracy.toStringAsFixed(1)}m '
                        '(maximum '
                        '${maxGpsAccuracyMeters.value.toStringAsFixed(0)}m)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: accuracyOkay ? null : colorScheme.error,
                        ),
                      ),
                      if (position.isMocked)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            'Mock location detected. '
                            'This information will be sent to the server.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(
                height: 16,
              ),
              Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor: colorScheme.primary.withValues(
                      alpha: 0.45,
                    ),
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  onPressed: isSubmittingAttendance.value
                      ? null
                      : () async {
                          Get.back();

                          final submitContext = Get.context;

                          if (submitContext != null) {
                            await submitAttendance(
                              submitContext,
                            );
                          }
                        },
                  child: isSubmittingAttendance.value
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm Attendance',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  // ===========================================================================
  // SUBMIT ATTENDANCE
  // ===========================================================================

  Future<void> submitAttendance(
    BuildContext context,
  ) async {
    if (isSubmittingAttendance.value) {
      return;
    }

    if (employeeID.value.trim().isEmpty) {
      AppAlert.show(
        context: context,
        type: AppAlertType.error,
        title: 'Employee Not Found',
        message: 'Employee number is unavailable. '
            'Please log in again.',
      );

      return;
    }

    isSubmittingAttendance.value = true;

    try {
      // -----------------------------------------------------------------------
      // 1. Load locations if needed
      // -----------------------------------------------------------------------

      if (selectedWorkMode.value == AttendanceWorkMode.onSite &&
          authorizedLocations.isEmpty) {
        await fetchAuthorizedLocations();

        if (authorizedLocations.isEmpty) {
          throw Exception(
            'No authorized attendance location is assigned to this employee.',
          );
        }
      }

      // -----------------------------------------------------------------------
      // 2. Fresh GPS fix
      // -----------------------------------------------------------------------

      final position = await _getFreshPosition();

      if (position == null) {
        AppAlert.show(
          context: context,
          type: AppAlertType.warning,
          title: 'Location Missing',
          message: 'Unable to get your current location. '
              'Please enable GPS and try again.',
        );

        return;
      }

      // -----------------------------------------------------------------------
      // 3. Validate coordinates
      // -----------------------------------------------------------------------

      if (!_isValidLatitude(
        position.latitude,
      )) {
        throw Exception(
          'Invalid latitude received from GPS.',
        );
      }

      if (!_isValidLongitude(
        position.longitude,
      )) {
        throw Exception(
          'Invalid longitude received from GPS.',
        );
      }

      // -----------------------------------------------------------------------
      // 4. Authorized On-site location check
      // -----------------------------------------------------------------------

      _calculateOfficeDistance();

      if (selectedWorkMode.value == AttendanceWorkMode.onSite) {
        if (selectedAuthorizedLocation.value == null ||
            !isInsideOfficeRadius.value) {
          final nearest = nearestAuthorizedLocation.value;

          final distance = distanceFromOfficeMeters.value;

          if (nearest != null && distance != null) {
            throw Exception(
              'Current location is not authorized. '
              'Nearest authorized location is '
              '${nearest.locationName}, '
              '${distance.toStringAsFixed(1)} meters away. '
              'Allowed radius is '
              '${nearest.allowedRadiusMeters.toStringAsFixed(0)} meters.',
            );
          }

          throw Exception(
            'Current location is not inside any authorized attendance location.',
          );
        }
      }

      // -----------------------------------------------------------------------
      // 5. Capture time
      // -----------------------------------------------------------------------

      final punchTime = DateTime.now();

      final locationCapturedAt = position.timestamp;

      // -----------------------------------------------------------------------
      // 6. Device metadata
      // -----------------------------------------------------------------------

      if (deviceId.value.trim().isEmpty || appVersion.value.trim().isEmpty) {
        await _loadDeviceMetadata();
      }

      final selectedLocation = selectedAuthorizedLocation.value;

      // -----------------------------------------------------------------------
      // 7. Build request payload
      // -----------------------------------------------------------------------

      final payload = <String, dynamic>{
        'employeeid': employeeID.value.trim(),

        'datetime': DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(
          punchTime,
        ),

        'latitude': position.latitude,

        'longitude': position.longitude,

        'address': currentAddress.value.trim().isEmpty
            ? _coordinateFallbackAddress(
                position.latitude,
                position.longitude,
              )
            : currentAddress.value.trim(),

        /// OFFICE / WFH
        'selected_mode': selectedWorkMode.value.apiValue,

        /// Backend determines IN / OUT.
        'punch_type': 'UNKNOWN',

        'device_id': deviceId.value.trim(),

        'device_name': deviceName.value.trim(),

        'device_os': deviceOS.value.trim(),

        'app_version': appVersion.value.trim(),

        'gps_accuracy_meters': position.accuracy,

        'location_captured_at': DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(
          locationCapturedAt,
        ),

        'is_mock_location': position.isMocked,

        'reason': _nullableString(
          reason.value,
        ),

        'photo_url': _nullableString(
          photoUrl.value,
        ),

        'document_url': _nullableString(
          documentUrl.value,
        ),
      };

      // -----------------------------------------------------------------------
      // Do NOT require these fields server-side unless backend accepts them.
      // They are included only when an On-site authorized location matched.
      // -----------------------------------------------------------------------

      if (selectedWorkMode.value == AttendanceWorkMode.onSite &&
          selectedLocation != null) {
        payload['authorized_location_id'] = selectedLocation.id;

        payload['attendance_location_id'] =
            selectedLocation.attendanceLocationId;

        payload['authorized_location_name'] = selectedLocation.locationName;

        payload['authorized_location_source'] = selectedLocation.source;
      }

      print(
        '📤 ========================================',
      );

      print(
        '📤 MOBILE ATTENDANCE REQUEST',
      );

      print(
        '📤 Employee: ${payload['employeeid']}',
      );

      print(
        '📤 DateTime: ${payload['datetime']}',
      );

      print(
        '📤 Latitude: ${payload['latitude']}',
      );

      print(
        '📤 Longitude: ${payload['longitude']}',
      );

      print(
        '📤 Mode: ${payload['selected_mode']}',
      );

      print(
        '📤 Punch Type: ${payload['punch_type']}',
      );

      print(
        '📤 GPS Accuracy: ${payload['gps_accuracy_meters']}',
      );

      if (selectedLocation != null) {
        print(
          '📤 Authorized Location: '
          '${selectedLocation.locationName}',
        );

        print(
          '📤 Authorized Location ID: '
          '${selectedLocation.id}',
        );

        print(
          '📤 Authorized Radius: '
          '${selectedLocation.allowedRadiusMeters}m',
        );

        print(
          '📤 Distance: '
          '${distanceFromOfficeMeters.value?.toStringAsFixed(2)}m',
        );
      }

      print(
        '📤 Mock Location: '
        '${payload['is_mock_location']}',
      );

      print(
        '📤 Device: '
        '${payload['device_name']}',
      );

      print(
        '📤 OS: '
        '${payload['device_os']}',
      );

      print(
        '📤 App Version: '
        '${payload['app_version']}',
      );

      print(
        '📤 Payload: $payload',
      );

      print(
        '📤 ========================================',
      );

      // -----------------------------------------------------------------------
      // 8. Submit
      // -----------------------------------------------------------------------

      await authService.attendance.addAttendance(
        payload,
      );

      // -----------------------------------------------------------------------
      // 9. Refresh attendance
      // -----------------------------------------------------------------------

      await fetchTodayAttendance();

      if (!context.mounted) {
        return;
      }

      final successLocationText =
          selectedWorkMode.value == AttendanceWorkMode.onSite &&
                  selectedLocation != null
              ? '\n${selectedLocation.locationName}'
              : '';

      AppAlert.show(
        context: context,
        type: AppAlertType.success,
        title: 'Attendance Submitted',
        message: '${selectedWorkMode.value.label}'
            '$successLocationText\n'
            '${currentAddress.value}\n\n'
            'Your attendance has been submitted successfully.',
        closeText: 'OK',
        actions: [
          AppAlertAction(
            label: 'OK',
            isPrimary: true,
            onPressed: () {
              Get.back();

              Get.offAll(
                () => DashboardScreen(),
              );
            },
          ),
        ],
      );
    } catch (error, stackTrace) {
      print(
        '❌ Submit attendance error: $error',
      );

      print(
        stackTrace,
      );

      if (!context.mounted) {
        return;
      }

      AppAlert.show(
        context: context,
        type: AppAlertType.error,
        title: 'Attendance Failed',
        message: _attendanceErrorMessage(
          error,
        ),
        closeText: 'Try Again',
      );
    } finally {
      isSubmittingAttendance.value = false;

      isButtonDisabled.value = false;
    }
  }

  // ===========================================================================
  // VALUE HELPERS
  // ===========================================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  bool _toBool(
    dynamic value,
  ) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }

  bool _isValidLatitude(
    double latitude,
  ) {
    return latitude >= -90 && latitude <= 90;
  }

  bool _isValidLongitude(
    double longitude,
  ) {
    return longitude >= -180 && longitude <= 180;
  }

  String? _nullableString(
    String? value,
  ) {
    final normalized = value?.trim() ?? '';

    return normalized.isEmpty ? null : normalized;
  }

  // ===========================================================================
  // ALERT
  // ===========================================================================

  void _showAlert(
    AppAlertType type,
    String title,
    String text,
  ) {
    final context = Get.context;

    if (context == null) {
      return;
    }

    AppAlert.show(
      context: context,
      type: type,
      title: title,
      message: text,
      closeText: 'OK',
    );
  }

  String _attendanceErrorMessage(
    Object error,
  ) {
    if (error is DioException || error is ApiException) {
      return ApiErrorHandler.getMessage(
        error,
      );
    }

    String message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message = message.substring(
        'Exception: '.length,
      );
    }

    final errorMessage = message.toLowerCase();

    if (errorMessage.contains(
          'no authorized attendance location',
        ) ||
        errorMessage.contains(
          'no authorized on-site',
        )) {
      return 'No authorized On-site attendance location '
          'is assigned to your employee account.';
    }

    if (errorMessage.contains(
          'current location is not authorized',
        ) ||
        (errorMessage.contains(
              'location',
            ) &&
            errorMessage.contains(
              'authorized',
            ))) {
      return message;
    }

    if (errorMessage.contains(
          'duplicate',
        ) ||
        (errorMessage.contains(
              'already',
            ) &&
            errorMessage.contains(
              'attendance',
            ))) {
      return 'This attendance punch has already been submitted.';
    }

    if (errorMessage.contains(
      'mock',
    )) {
      return 'The server rejected the attendance because '
          'a mock location was detected.';
    }

    if (errorMessage.contains(
      'timeout',
    )) {
      return 'The attendance request timed out. '
          'Please check your internet connection and try again.';
    }

    if (errorMessage.contains(
          'socket',
        ) ||
        errorMessage.contains(
          'connection',
        ) ||
        errorMessage.contains(
          'network',
        )) {
      return 'Unable to connect to the server. '
          'Please check your internet connection.';
    }

    if (errorMessage.contains(
          '401',
        ) ||
        errorMessage.contains(
          'unauthorized',
        )) {
      return 'Your login session has expired. '
          'Please log in again.';
    }

    if (errorMessage.contains(
          '403',
        ) ||
        errorMessage.contains(
          'forbidden',
        )) {
      return 'You do not have permission to mark attendance.';
    }

    if (message.trim().isNotEmpty && message != error.toString()) {
      return message;
    }

    return 'Unable to mark attendance. Please try again.';
  }

  // ===========================================================================
  // FETCH TODAY ATTENDANCE
  // ===========================================================================

  Future<void> fetchTodayAttendance() async {
    if (employeeID.value.isEmpty) {
      _clearAttendanceData();

      return;
    }

    if (isLoadingAttendance.value) {
      return;
    }

    isLoadingAttendance.value = true;

    try {
      final records = await authService.attendance.fetchAttendanceData(
        employeeID.value,
        DateTime.now(),
      );

      if (records.isEmpty) {
        _clearAttendanceData();

        return;
      }

      final normalizedRecords = records
          .whereType<Map>()
          .map(
            (
              record,
            ) =>
                Map<String, dynamic>.from(
              record,
            ),
          )
          .toList();

      if (normalizedRecords.isEmpty) {
        _clearAttendanceData();

        return;
      }

      final punches = <_AttendancePunch>[];

      for (final record in normalizedRecords) {
        punches.addAll(
          _extractPunchesFromRecord(
            record,
          ),
        );
      }

      if (punches.isEmpty) {
        _loadDailyAttendanceFallback(
          normalizedRecords,
        );

        return;
      }

      punches.sort(
        (
          first,
          second,
        ) =>
            first.dateTime.compareTo(
          second.dateTime,
        ),
      );

      final checkInPunches = punches
          .where(
            (
              punch,
            ) =>
                punch.action == 'CHECK_IN',
          )
          .toList();

      final checkOutPunches = punches
          .where(
            (
              punch,
            ) =>
                punch.action == 'CHECK_OUT',
          )
          .toList();

      if (checkInPunches.isNotEmpty) {
        final firstCheckIn = checkInPunches.first;

        checkINTime.value = _formatAttendanceDisplayTime(
          firstCheckIn.displayTime,
          firstCheckIn.dateTime,
        );

        checkINType.value =
            firstCheckIn.type.isEmpty ? 'Check In' : firstCheckIn.type;
      } else {
        checkINTime.value = '';

        checkINType.value = '';
      }

      if (checkOutPunches.isNotEmpty) {
        final lastCheckOut = checkOutPunches.last;

        checkOutTime.value = _formatAttendanceDisplayTime(
          lastCheckOut.displayTime,
          lastCheckOut.dateTime,
        );

        checkOutType.value =
            lastCheckOut.type.isEmpty ? 'Check Out' : lastCheckOut.type;
      } else {
        checkOutTime.value = '';

        checkOutType.value = '';
      }

      latestPunchAction.value = punches.last.action;

      print(
        '✅ Attendance loaded:',
      );

      print(
        '   First check-in: ${checkINTime.value}',
      );

      print(
        '   Latest check-out: ${checkOutTime.value}',
      );

      print(
        '   Last effective backend punch: ${latestPunchAction.value}',
      );

      print(
        '   Expected next UI action: $nextAttendanceAction',
      );

      print(
        '   API punch_type: UNKNOWN',
      );
    } catch (error, stackTrace) {
      print(
        '❌ Fetch today attendance error: $error',
      );

      print(
        stackTrace,
      );

      _clearAttendanceData();
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  List<_AttendancePunch> _extractPunchesFromRecord(
    Map<String, dynamic> record,
  ) {
    final punches = <_AttendancePunch>[];

    final workDate = _readRecordValue(
      record,
      [
        'work_date_local',
        'work_date',
        'attendance_date',
        'date',
      ],
    );

    final directAction = _normalizePunchAction(
      _readRecordValue(
        record,
        [
          'effective_punch_type',
          'resolved_punch_type',
          'punch_type',
          'attendance_action',
          'action',
          'attendance_type',
        ],
      ),
    );

    final directTime = _readRecordValue(
      record,
      [
        'punch_time',
        'datetime',
        'recorded_at',
        'created_at',
        'createdAt',
      ],
    );

    if (directAction != null && directTime.isNotEmpty) {
      final parsedDateTime = _parseAttendanceDateTime(
        directTime,
        workDate: workDate,
      );

      if (parsedDateTime != null) {
        punches.add(
          _AttendancePunch(
            action: directAction,
            displayTime: directTime,
            type: directAction == 'CHECK_IN' ? 'Check In' : 'Check Out',
            dateTime: parsedDateTime,
          ),
        );
      }

      return punches;
    }

    final checkInTime = _readRecordValue(
      record,
      [
        'checkIN_time',
        'checkin_time',
        'check_in_time',
      ],
    );

    if (checkInTime.isNotEmpty) {
      final checkInDateTime = _parseAttendanceDateTime(
        checkInTime,
        workDate: workDate,
      );

      if (checkInDateTime != null) {
        punches.add(
          _AttendancePunch(
            action: 'CHECK_IN',
            displayTime: checkInTime,
            type: _readRecordValue(
              record,
              [
                'checkIN_type',
                'checkin_type',
                'check_in_type',
              ],
            ),
            dateTime: checkInDateTime,
          ),
        );
      }
    }

    final checkOutTime = _readRecordValue(
      record,
      [
        'checkOUT_time',
        'checkout_time',
        'check_out_time',
      ],
    );

    if (checkOutTime.isNotEmpty) {
      final checkOutDateTime = _parseAttendanceDateTime(
        checkOutTime,
        workDate: workDate,
      );

      if (checkOutDateTime != null) {
        punches.add(
          _AttendancePunch(
            action: 'CHECK_OUT',
            displayTime: checkOutTime,
            type: _readRecordValue(
              record,
              [
                'checkOUT_type',
                'checkout_type',
                'check_out_type',
              ],
            ),
            dateTime: checkOutDateTime,
          ),
        );
      }
    }

    return punches;
  }

  void _loadDailyAttendanceFallback(
    List<Map<String, dynamic>> records,
  ) {
    String firstCheckInTime = '';
    String firstCheckInType = '';

    String latestCheckOutTime = '';
    String latestCheckOutType = '';

    DateTime? firstCheckInDateTime;
    DateTime? latestCheckOutDateTime;

    for (final record in records) {
      final workDate = _readRecordValue(
        record,
        [
          'work_date_local',
          'work_date',
          'attendance_date',
          'date',
        ],
      );

      final checkInTime = _readRecordValue(
        record,
        [
          'checkIN_time',
          'checkin_time',
          'check_in_time',
        ],
      );

      if (checkInTime.isNotEmpty) {
        final parsedCheckIn = _parseAttendanceDateTime(
          checkInTime,
          workDate: workDate,
        );

        if (parsedCheckIn != null &&
            (firstCheckInDateTime == null ||
                parsedCheckIn.isBefore(
                  firstCheckInDateTime,
                ))) {
          firstCheckInDateTime = parsedCheckIn;

          firstCheckInTime = checkInTime;

          firstCheckInType = _readRecordValue(
            record,
            [
              'checkIN_type',
              'checkin_type',
              'check_in_type',
            ],
          );
        }
      }

      final checkOutTime = _readRecordValue(
        record,
        [
          'checkOUT_time',
          'checkout_time',
          'check_out_time',
        ],
      );

      if (checkOutTime.isNotEmpty) {
        final parsedCheckOut = _parseAttendanceDateTime(
          checkOutTime,
          workDate: workDate,
        );

        if (parsedCheckOut != null &&
            (latestCheckOutDateTime == null ||
                parsedCheckOut.isAfter(
                  latestCheckOutDateTime,
                ))) {
          latestCheckOutDateTime = parsedCheckOut;

          latestCheckOutTime = checkOutTime;

          latestCheckOutType = _readRecordValue(
            record,
            [
              'checkOUT_type',
              'checkout_type',
              'check_out_type',
            ],
          );
        }
      }
    }

    checkINTime.value = firstCheckInDateTime == null
        ? ''
        : _formatAttendanceDisplayTime(
            firstCheckInTime,
            firstCheckInDateTime,
          );

    checkINType.value = firstCheckInType;

    checkOutTime.value = latestCheckOutDateTime == null
        ? ''
        : _formatAttendanceDisplayTime(
            latestCheckOutTime,
            latestCheckOutDateTime,
          );

    checkOutType.value = latestCheckOutType;

    if (latestCheckOutDateTime != null &&
        (firstCheckInDateTime == null ||
            latestCheckOutDateTime.isAfter(
              firstCheckInDateTime,
            ))) {
      latestPunchAction.value = 'CHECK_OUT';
    } else if (firstCheckInDateTime != null) {
      latestPunchAction.value = 'CHECK_IN';
    } else {
      latestPunchAction.value = 'CHECK_OUT';
    }

    print(
      '✅ Daily attendance fallback loaded:',
    );

    print(
      '   First check-in: ${checkINTime.value}',
    );

    print(
      '   Latest check-out: ${checkOutTime.value}',
    );

    print(
      '   UI last action: ${latestPunchAction.value}',
    );
  }

  String? _normalizePunchAction(
    String action,
  ) {
    final normalized = action
        .trim()
        .toUpperCase()
        .replaceAll(
          '-',
          '_',
        )
        .replaceAll(
          ' ',
          '_',
        );

    if (normalized == 'CHECK_IN' ||
        normalized == 'CHECKIN' ||
        normalized == 'IN') {
      return 'CHECK_IN';
    }

    if (normalized == 'CHECK_OUT' ||
        normalized == 'CHECKOUT' ||
        normalized == 'OUT') {
      return 'CHECK_OUT';
    }

    return null;
  }

  DateTime? _parseAttendanceDateTime(
    String value, {
    String workDate = '',
  }) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return null;
    }

    final directParse = DateTime.tryParse(
      trimmedValue,
    );

    if (directParse != null) {
      return directParse;
    }

    String selectedDate = workDate.trim();

    if (selectedDate.isEmpty) {
      selectedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(
        DateTime.now(),
      );
    }

    if (selectedDate.length > 10) {
      selectedDate = selectedDate.substring(
        0,
        10,
      );
    }

    final possibleValues = <String>[
      trimmedValue,
      '$selectedDate $trimmedValue',
    ];

    final formats = <DateFormat>[
      DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ),
      DateFormat(
        'yyyy-MM-dd HH:mm',
      ),
      DateFormat(
        'yyyy-MM-dd hh:mm:ss a',
      ),
      DateFormat(
        'yyyy-MM-dd hh:mm a',
      ),
      DateFormat(
        'HH:mm:ss',
      ),
      DateFormat(
        'HH:mm',
      ),
      DateFormat(
        'hh:mm:ss a',
      ),
      DateFormat(
        'hh:mm a',
      ),
    ];

    for (final possibleValue in possibleValues) {
      for (final format in formats) {
        try {
          return format.parseStrict(
            possibleValue,
          );
        } catch (_) {
          // Continue.
        }
      }
    }

    return null;
  }

  String _formatAttendanceDisplayTime(
    String originalValue,
    DateTime dateTime,
  ) {
    final value = originalValue.trim();

    if (RegExp(
      r'^\d{1,2}:\d{2}(:\d{2})?(\s?[APMapm]{2})?$',
    ).hasMatch(
      value,
    )) {
      return value;
    }

    return DateFormat(
      'HH:mm:ss',
    ).format(
      dateTime,
    );
  }

  String _readRecordValue(
    dynamic record,
    List<String> keys,
  ) {
    if (record is! Map) {
      return '';
    }

    for (final key in keys) {
      final value = record[key];

      if (value == null) {
        continue;
      }

      final stringValue = value.toString().trim();

      if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
        return stringValue;
      }
    }

    return '';
  }

  void _clearAttendanceData() {
    checkINTime.value = '';

    checkOutTime.value = '';

    checkINType.value = '';

    checkOutType.value = '';

    latestPunchAction.value = 'CHECK_OUT';
  }

  // ===========================================================================
  // SETTINGS / RETRY
  // ===========================================================================

  Future<void> retryLocation() async {
    await fetchAuthorizedLocations();

    await fetchAndShowLocation();

    if (positionStream == null) {
      await _initLocation();
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (error) {
      print(
        '❌ Open location settings error: $error',
      );
    }
  }

  Future<void> openApplicationSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error) {
      print(
        '❌ Open application settings error: $error',
      );
    }
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================

  @override
  void onClose() {
    _cameraDebounce?.cancel();

    _addressDebounce?.cancel();

    positionStream?.cancel();

    positionStream = null;

    googleMapController = null;

    mapReady = false;

    super.onClose();
  }
}
