// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/auth/notification_service.dart';
import 'package:corehris/auth/socketnotification_service.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/pinlogin_page.dart';
import 'package:corehris/modules/MASTER/splash_screen.dart';
import 'package:corehris/theme/theme.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

const String kOnboardingCompletedKey = 'hasSeenSplash';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<AuthService>(
    AuthService(),
    permanent: true,
  );

  Get.put<ThemeController>(
    ThemeController(),
    permanent: true,
  );

  runApp(const MyApp());
}

// ============================================================
// SOCKET CONNECTION
// ============================================================

Future<void> _connectSocketIfPossible() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('username');

    if (empId == null || empId.trim().isEmpty) return;

    final auth = Get.find<AuthService>();
    final base = (auth.currentApiBaseUrl ?? '').trim();

    if (base.isEmpty) {
      debugPrint(
        'Socket not connected: tenant backend URL is not ready.',
      );
      return;
    }

    SocketNotificationService.connectSocket(empId, base);

    debugPrint('Socket connected for $empId');
  } catch (e) {
    debugPrint('Socket connection error: $e');
  }
}

Future<void> reconnectSocketAfterLogin() async {
  await _connectSocketIfPossible();
}

// ============================================================
// IOS TRACKING TRANSPARENCY
// ============================================================

Future<void> _initTrackingTransparency() async {
  if (!Platform.isIOS) return;

  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    debugPrint('Tracking transparency initialized');
  } catch (e) {
    debugPrint('Tracking transparency error: $e');
  }
}

// ============================================================
// MAIN APP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talexa HRMS',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeController.themeMode.value,
        home: const AppBootstrapScreen(),
      ),
    );
  }
}

// ============================================================
// APP BOOTSTRAP
// ============================================================

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    final auth = Get.find<AuthService>();
    final themeController = Get.find<ThemeController>();

    await Future.wait([
      auth.initialize(),
      themeController.loadTheme(),
      LocalNotificationService.initialize(),
    ]);

    unawaited(_connectSocketIfPossible());
    unawaited(_initTrackingTransparency());
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = _bootstrapApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingScreen();
        }

        if (snapshot.hasError) {
          return _StartupErrorScreen(
            onRetry: _retryBootstrap,
          );
        }

        return const InitialScreen();
      },
    );
  }
}

// ============================================================
// INITIAL SCREEN DECIDER
// ============================================================

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  late Future<Widget> _startScreenFuture;

  @override
  void initState() {
    super.initState();
    _startScreenFuture = _decideStartScreen();
  }

  Future<Widget> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSplash', false);
    // Check whether onboarding was completed previously.
    final bool hasSeenSplash = prefs.getBool(kOnboardingCompletedKey) ?? false;

    debugPrint('Onboarding completed: $hasSeenSplash');

    // First launch: show onboarding.
    if (!hasSeenSplash) {
      return const SplashScreen();
    }

    // Returning user: check authentication.
    try {
      final auth = Get.find<AuthService>();

      final bool alreadyLoggedIn = await auth.isLoggedIn();

      if (!alreadyLoggedIn) {
        return const LoginScreen();
      }

      final savedPin = prefs.getString('saved_pin');

      if (savedPin != null && savedPin.isNotEmpty) {
        return PinLoginScreen();
      }

      return const LoginScreen();
    } catch (e) {
      debugPrint('Initial authentication check failed: $e');

      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingScreen();
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to load the app. Please restart.',
              ),
            ),
          );
        }

        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}

// ============================================================
// LOADING SCREEN
// ============================================================

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1769E8),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR SCREEN
// ============================================================

class _StartupErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorScreen({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Color(0xFF1769E8),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to start Talexa HRMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Something went wrong while starting the app. Please try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
