class UrlHelpers {
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static String? extractBackendUrl(dynamic root,
      {required String preferredSystemCode}) {
    if (root is! Map) return null;
    final systems = root['systems'];
    if (systems is! List) return null;

    for (final s in systems) {
      if (s is Map) {
        final code = (s['system_code'] ?? '').toString().trim();
        if (code == preferredSystemCode) {
          final url = (s['backend_url'] ?? '').toString().trim();
          if (url.isNotEmpty) return url;
        }
      }
    }

    for (final s in systems) {
      if (s is Map) {
        final url = (s['backend_url'] ?? '').toString().trim();
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }
}
