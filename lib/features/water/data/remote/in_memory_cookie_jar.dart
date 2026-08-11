import 'dart:io';

class InMemoryCookieJar {
  final _cookies = <_StoredCookie>[];

  bool get isEmpty => _cookies.isEmpty;

  void store(Uri origin, List<Cookie> cookies) {
    final now = DateTime.now().toUtc();
    for (final cookie in cookies) {
      final domain = (cookie.domain ?? origin.host).replaceFirst(
        RegExp(r'^\.'),
        '',
      );
      if (domain != origin.host) continue;
      final path = cookie.path?.isNotEmpty == true ? cookie.path! : '/';
      _cookies.removeWhere(
        (stored) =>
            stored.cookie.name == cookie.name &&
            stored.domain == domain &&
            stored.path == path,
      );
      if (cookie.expires != null && !cookie.expires!.toUtc().isAfter(now)) {
        continue;
      }
      _cookies.add(_StoredCookie(cookie: cookie, domain: domain, path: path));
    }
  }

  List<Cookie> cookiesFor(Uri uri) {
    final now = DateTime.now().toUtc();
    _cookies.removeWhere(
      (stored) =>
          stored.cookie.expires != null &&
          !stored.cookie.expires!.toUtc().isAfter(now),
    );
    return _cookies
        .where(
          (stored) =>
              stored.domain == uri.host &&
              uri.path.startsWith(stored.path) &&
              (!stored.cookie.secure || uri.scheme == 'https'),
        )
        .map((stored) => stored.cookie)
        .toList(growable: false);
  }

  void clear() => _cookies.clear();

  @override
  String toString() => 'InMemoryCookieJar(count: ${_cookies.length})';
}

class _StoredCookie {
  const _StoredCookie({
    required this.cookie,
    required this.domain,
    required this.path,
  });

  final Cookie cookie;
  final String domain;
  final String path;
}
