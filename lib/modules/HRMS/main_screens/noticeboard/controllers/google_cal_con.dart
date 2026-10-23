// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GoogleCalendarService {
  final _storage = const FlutterSecureStorage();

  // OAuth scopes – read-only calendar access
  static const _scopes = [gcal.CalendarApi.calendarReadonlyScope];

  // Client ID + Secret (from Google Cloud Console)
  static final _clientId = ClientId(
    "687761717173-u9qh81t8680d90cit3t0059kok05c8gp.apps.googleusercontent.com",
    "YOUR_CLIENT_SECRET", // Optional for "installed" apps
  );

  // Public API key (same as your Maps key)
  static const _apiKey = "AIzaSyDzkq1bnohYwk3oxbCm4yDgHnOSBI-Tq4E";

  AutoRefreshingAuthClient? _authClient;

  /// 🔹 Try to authenticate or reuse saved credentials
  Future<AutoRefreshingAuthClient?> authenticate() async {
    try {
      final saved = await _storage.read(key: 'google_credentials');

      if (saved != null) {
        // Reuse saved credentials
        final creds = AccessCredentials.fromJson(jsonDecode(saved));
        final client = http.Client();
        _authClient = autoRefreshingClient(_clientId, creds, client);
        print("✅ Reused existing Google credentials");
        return _authClient;
      }

      // Otherwise request user consent (first time)
      print("🌐 Requesting new Google OAuth consent...");
      _authClient = await clientViaUserConsent(_clientId, _scopes, _promptUser);

      // Save credentials securely
      await _storage.write(
        key: 'google_credentials',
        value: jsonEncode(_authClient!.credentials.toJson()),
      );

      return _authClient;
    } catch (e) {
      print("❌ Google OAuth failed: $e");
      return null;
    }
  }

  void _promptUser(String url) {
    print("\n🔗 Please open this link to grant Google Calendar access:");
    print(url);
    if (Platform.isIOS || Platform.isAndroid) {
      print("📱 (Copy & open this link in Safari/Chrome on your device)");
    }
  }

  /// 🔹 Fetch user’s personal calendar events
  Future<List<gcal.Event>> fetchEvents(AutoRefreshingAuthClient client) async {
    try {
      final api = gcal.CalendarApi(client);
      final now = DateTime.now();

      final events = await api.events.list(
        "primary",
        timeMin: now.subtract(const Duration(days: 30)),
        timeMax: now.add(const Duration(days: 60)),
        singleEvents: true,
        orderBy: "startTime",
      );

      final count = events.items?.length ?? 0;
      print("📅 Loaded $count personal calendar events");
      return events.items ?? [];
    } catch (e) {
      print("❌ Error fetching user events: $e");
      return [];
    }
  }

  /// 🔹 Fetch public holidays using Google’s public holiday calendars
  Future<List<gcal.Event>> fetchPublicHolidayEvents(
      {String? calendarId}) async {
    try {
      final now = DateTime.now();

      // 🔹 Auto-detect locale-based calendar if not provided
      calendarId ??= _getHolidayCalendarId();

      final url =
          "https://www.googleapis.com/calendar/v3/calendars/$calendarId/events?"
          "key=$_apiKey"
          "&singleEvents=true"
          "&orderBy=startTime"
          "&timeMin=${now.subtract(const Duration(days: 30)).toUtc().toIso8601String()}"
          "&timeMax=${now.add(const Duration(days: 365)).toUtc().toIso8601String()}";

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = data['items'] as List<dynamic>? ?? [];
        print("🎉 Retrieved ${items.length} public holiday events");
        return items.map((e) => gcal.Event.fromJson(e)).toList();
      } else {
        print("⚠️ Failed to fetch holidays (HTTP ${res.statusCode})");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching holidays: $e");
      return [];
    }
  }

  /// 🔹 Detect correct holiday calendar based on locale
  String _getHolidayCalendarId() {
    final locale = Intl.getCurrentLocale().toLowerCase();
    if (locale.contains("lk"))
      return "en.lk#holiday@group.v.calendar.google.com";
    if (locale.contains("in"))
      return "en.indian#holiday@group.v.calendar.google.com";
    if (locale.contains("us"))
      return "en.usa#holiday@group.v.calendar.google.com";
    if (locale.contains("uk"))
      return "en.uk#holiday@group.v.calendar.google.com";
    if (locale.contains("ca"))
      return "en.canadian#holiday@group.v.calendar.google.com";
    return "en.lk#holiday@group.v.calendar.google.com"; // default fallback
  }

  /// 🔹 Force re-login (clear saved tokens)
  Future<void> logout() async {
    await _storage.delete(key: 'google_credentials');
    _authClient?.close();
    _authClient = null;
    print("🧹 Cleared saved Google tokens");
  }
}
