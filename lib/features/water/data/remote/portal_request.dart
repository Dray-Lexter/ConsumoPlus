class PortalRequest {
  const PortalRequest({
    required this.method,
    required this.uri,
    this.formFields = const {},
  });

  final String method;
  final Uri uri;
  final Map<String, String> formFields;

  @override
  String toString() => 'PortalRequest($method ${uri.path})';
}
