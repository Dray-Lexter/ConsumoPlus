sealed class ElectricityException implements Exception {
  const ElectricityException(this.sanitizedCode, this.userMessage);

  final String sanitizedCode;
  final String userMessage;

  @override
  String toString() => '$runtimeType($sanitizedCode)';
}

final class ElectricityInvalidCredentialsException
    extends ElectricityException {
  const ElectricityInvalidCredentialsException()
    : super(
        'invalid_credentials',
        'No pudimos ingresar. Revisa tu número de contrato y clave de Electrosur.',
      );
}

final class ElectricitySessionExpiredException extends ElectricityException {
  const ElectricitySessionExpiredException()
    : super(
        'session_expired',
        'La sesión con Electrosur terminó. Ingresa tu clave nuevamente.',
      );
}

final class ElectrosurUnavailableException extends ElectricityException {
  const ElectrosurUnavailableException()
    : super(
        'portal_unavailable',
        'Electrosur no está disponible en este momento. Intenta más tarde.',
      );
}

final class ElectricitySectionStructureException extends ElectricityException {
  const ElectricitySectionStructureException(String section)
    : super(
        'unexpected_${section}_structure',
        section == 'response'
            ? 'Ingresamos a Electrosur, pero no pudimos interpretar la respuesta del portal con seguridad.'
            : section == 'account_status'
            ? 'Ingresamos a Electrosur, pero no pudimos leer Estado de cuenta con seguridad.'
            : section == 'consumptions'
            ? 'Ingresamos a Electrosur, pero no pudimos leer Consumos con seguridad.'
            : section == 'payments'
            ? 'Ingresamos a Electrosur, pero no pudimos leer Pagos con seguridad.'
            : section == 'supply'
            ? 'Ingresamos a Electrosur, pero no pudimos leer Datos del suministro con seguridad.'
            : 'Ingresamos a Electrosur, pero no pudimos leer una sección con seguridad.',
      );
}

final class ElectricityLocalStorageException extends ElectricityException {
  const ElectricityLocalStorageException()
    : super(
        'local_storage',
        'No pudimos guardar la actualización. Tus datos anteriores se conservaron.',
      );
}

final class ElectricityNetworkTimeoutException extends ElectricityException {
  const ElectricityNetworkTimeoutException()
    : super(
        'network_timeout',
        'La consulta demoró demasiado. Revisa tu conexión e intenta nuevamente.',
      );
}

final class ElectricityIncompleteSynchronizationException
    extends ElectricityException {
  const ElectricityIncompleteSynchronizationException()
    : super(
        'incomplete_synchronization',
        'La actualización quedó incompleta. Tus datos anteriores se conservaron.',
      );
}
