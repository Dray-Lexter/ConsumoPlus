import '../../core/models/utility_type.dart';

abstract final class AppCopy {
  static const welcomeTitle = 'Bienvenido a ConsumoPlus';
  static const settingsTooltip = 'Configuración';
  static const settingsTitle = 'Configuración';
  static const appearanceTitle = 'Apariencia';
  static const appearanceDescription = 'Disponible en una versión posterior';
  static const privacyStorageTitle = 'Privacidad y almacenamiento local';
  static const versionLabel = 'Versión';
  static const homeTitle =
      'Explora una forma sencilla de visualizar tus servicios de agua y electricidad';
  static const demoNotice =
      'ConsumoPlus solo consulta a los proveedores cuando tú lo solicitas y conserva una copia cifrada para usarla sin conexión.';
  static const splashTagline = 'Agua y electricidad, en un solo lugar';
  static const startupErrorTitle = 'No pudimos preparar ConsumoPlus';
  static const startupErrorMessage =
      'No pudimos completar el inicio. Intenta nuevamente.';
  static const retryAction = 'Intentar nuevamente';
  static const routeUnavailable = 'Ruta no disponible';
  static const demoLabel = 'Versión demostrativa';
  static const unavailableConnection =
      'La conexión con este proveedor todavía no está disponible.';

  static String utilityName(UtilityType type) => switch (type) {
    UtilityType.water => 'Agua',
    UtilityType.electricity => 'Electricidad',
  };
}
