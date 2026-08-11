class PasswordRequest {
  const PasswordRequest({required this.username, required this.password});

  final String username;
  final String password;

  @override
  String toString() => 'PasswordRequest(usernameConfigured: true)';
}
