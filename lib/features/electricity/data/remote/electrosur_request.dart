class ElectrosurRequest {
  const ElectrosurRequest({
    required this.method,
    required this.uri,
    this.formFields = const {},
  });

  final String method;
  final Uri uri;
  final Map<String, String> formFields;

  @override
  String toString() => 'ElectrosurRequest($method ${uri.path})';
}
