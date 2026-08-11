import '../../core/models/utility_type.dart';

abstract final class AppCopy {
  static const welcomeTitle = 'Bienvenido a ConsumoPlus';
  static const settingsTooltip = 'Configuración';
  static const settingsTitle = 'Configuración';
  static const privacyStorageTitle = 'Privacidad y almacenamiento local';
  static const privacyStorageDescription =
      'Tus datos locales se guardan cifrados en este dispositivo. '
      'ConsumoPlus no usa una nube propia para almacenar tu historial.';
  static const privacyCredentialsTitle = 'Contraseñas y sesiones';
  static const privacyCredentialsDescription =
      'Las contraseñas de EPS Tacna y Electrosur no se almacenan. '
      'Las cookies de sesión se mantienen solo durante cada sincronización.';
  static const privacyConnectionsTitle = 'Conexiones con proveedores';
  static const privacyConnectionsDescription =
      'Las conexiones dependen de las condiciones de seguridad de cada '
      'proveedor. EPS Tacna y Electrosur usan actualmente HTTP y requieren '
      'tu autorización explícita.';
  static const privacyControlTitle = 'Control de tus datos';
  static const privacyControlDescription =
      'Puedes eliminar los datos locales de Agua o Electricidad desde el '
      'módulo correspondiente.';
  static const versionLabel = 'Versión';
  static const homeTitle =
      'Explora una forma sencilla de visualizar tus servicios de agua y electricidad';
  static const localFirstNotice =
      'ConsumoPlus solo consulta a los proveedores cuando tú lo solicitas y conserva una copia cifrada para usarla sin conexión.';
  static const splashTagline = 'Agua y electricidad, en un solo lugar';
  static const startupErrorTitle = 'No pudimos preparar ConsumoPlus';
  static const startupErrorMessage =
      'No pudimos completar el inicio. Intenta nuevamente.';
  static const retryAction = 'Intentar nuevamente';
  static const routeUnavailable = 'Ruta no disponible';
  static const unavailableProviderLabel = 'Proveedor no disponible';
  static const unavailableConnection =
      'La conexión con este proveedor todavía no está disponible.';

  static String utilityName(UtilityType type) => switch (type) {
    UtilityType.water => 'Agua',
    UtilityType.electricity => 'Electricidad',
  };
}
