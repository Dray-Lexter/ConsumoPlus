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
        'La sesion con EPS Tacna termino. Ingresa tu clave nuevamente.',
      );
}

final class PortalUnavailableException extends WaterException {
  const PortalUnavailableException()
    : super(
        'portal_unavailable',
        'EPS Tacna no esta disponible en este momento. Intenta mas tarde.',
      );
}

final class UnexpectedPortalStructureException extends WaterException {
  const UnexpectedPortalStructureException()
    : super(
        'unexpected_portal_structure',
        'EPS Tacna cambio su pagina y no pudimos leer los datos con seguridad.',
      );
}

final class BillingHistoryStructureException extends WaterException {
  const BillingHistoryStructureException()
    : super(
        'billing_history_structure',
        'Ingresamos a EPS Tacna, pero no pudimos leer el historial de facturacion.',
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
        'No pudimos guardar la actualizacion en este dispositivo. Tus datos anteriores se conservaron.',
      );
}

final class NetworkTimeoutException extends WaterException {
  const NetworkTimeoutException()
    : super(
        'network_timeout',
        'La consulta demoro demasiado. Revisa tu conexion e intenta de nuevo.',
      );
}

final class IncompleteSynchronizationException extends WaterException {
  const IncompleteSynchronizationException()
    : super(
        'incomplete_synchronization',
        'La actualizacion quedo incompleta. Tus datos anteriores se conservaron.',
      );
}
