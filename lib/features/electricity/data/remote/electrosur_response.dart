class ElectrosurResponse {
  const ElectrosurResponse({
    required this.statusCode,
    required this.uri,
    required this.body,
    this.location,
    this.cookieNames = const {},
  });

  final int statusCode;
  final Uri uri;
  final String body;
  final String? location;
  final Set<String> cookieNames;

  @override
  String toString() => 'ElectrosurResponse($statusCode ${uri.path})';
}
