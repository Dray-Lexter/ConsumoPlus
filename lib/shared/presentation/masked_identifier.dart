String maskUtilityIdentifier(String value) {
  if (value.length <= 4) return '••••';
  final hidden = List.filled(value.length - 4, '•').join();
  return '$hidden${value.substring(value.length - 4)}';
}
