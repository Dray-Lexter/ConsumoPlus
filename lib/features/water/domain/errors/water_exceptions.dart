sealed class WaterException implements Exception {
  const WaterException(this.sanitizedCode, this.userMessage);

  final String sanitizedCode;
  final String userMessage;

  @override
  String toString() => '$runtimeType($sanitizedCode)';
}

final class InvalidCredentialsException extends WaterException {
  const InvalidCredentialsException()
    : super(
        'invalid_credentials',
        'No pudimos ingresar. Revisa tu usuario y clave de EPS Tacna.',
      );
}

final class SessionExpiredException extends WaterException {
  const SessionExpiredException()
    : super(
        'session_expired',
        'La sesión con EPS Tacna terminó. Ingresa tu clave nuevamente.',
      );
}

final class PortalUnavailableException extends WaterException {
  const PortalUnavailableException()
    : super(
        'portal_unavailable',
        'EPS Tacna no está disponible en este momento. Intenta más tarde.',
      );
}

final class UnexpectedPortalStructureException extends WaterException {
  const UnexpectedPortalStructureException()
    : super(
        'unexpected_portal_structure',
        'EPS Tacna cambió su página y no pudimos leer los datos con seguridad.',
      );
}

final class BillingHistoryStructureException extends WaterException {
  const BillingHistoryStructureException()
    : super(
        'billing_history_structure',
        'Ingresamos a EPS Tacna, pero no pudimos leer el historial de facturación.',
      );
}

final class PaymentHistoryStructureException extends WaterException {
  const PaymentHistoryStructureException()
    : super(
        'payment_history_structure',
        'Ingresamos a EPS Tacna, pero no pudimos leer el historial de pagos.',
      );
}

final class LocalStorageException extends WaterException {
  const LocalStorageException()
    : super(
        'local_storage',
        'No pudimos guardar la actualización en este dispositivo. Tus datos anteriores se conservaron.',
      );
}

final class NetworkTimeoutException extends WaterException {
  const NetworkTimeoutException()
    : super(
        'network_timeout',
        'La consulta demoró demasiado. Revisa tu conexión e intenta de nuevo.',
      );
}

final class IncompleteSynchronizationException extends WaterException {
  const IncompleteSynchronizationException()
    : super(
        'incomplete_synchronization',
        'La actualización quedó incompleta. Tus datos anteriores se conservaron.',
      );
}
