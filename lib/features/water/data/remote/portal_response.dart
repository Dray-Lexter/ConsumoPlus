class PortalResponse {
  const PortalResponse({
    required this.statusCode,
    required this.uri,
    required this.body,
  });

  final int statusCode;
  final Uri uri;
  final String body;

  @override
  String toString() => 'PortalResponse($statusCode ${uri.path})';
}
