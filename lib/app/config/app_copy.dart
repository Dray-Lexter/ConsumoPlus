import '../../core/models/utility_type.dart';

abstract final class AppCopy {
  static const welcomeTitle = 'Bienvenido a ConsumoPlus';
  static const settingsTooltip = 'Configuración';
  static const homeTitle =
      'Explora una forma sencilla de visualizar tus servicios de agua y electricidad';
  static const demoNotice =
      'Esta versión demostrativa todavía no se conecta con los proveedores';
  static const splashTagline = 'Agua y electricidad, en un solo lugar';
  static const startupErrorTitle = 'No pudimos preparar ConsumoPlus';
  static const startupErrorMessage =
      'No pudimos completar el inicio. Intenta nuevamente.';
  static const retryAction = 'Intentar nuevamente';
  static const routeUnavailable = 'Ruta no disponible';
  static const demoLabel = 'Demostración';
  static const unavailableConnection =
      'La conexión con este proveedor todavía no está disponible.';

  static String utilityName(UtilityType type) => switch (type) {
    UtilityType.water => 'Agua',
    UtilityType.electricity => 'Electricidad',
  };
}
