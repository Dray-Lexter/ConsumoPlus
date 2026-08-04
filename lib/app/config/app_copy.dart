import '../../core/models/utility_type.dart';

abstract final class AppCopy {
  static const homeTitle =
      'Explora una forma sencilla de visualizar tus servicios de agua y electricidad';
  static const demoNotice =
      'Esta versión demostrativa todavía no se conecta con los proveedores';
  static const splashTagline = 'Agua y electricidad, en un solo lugar';
  static const demoLabel = 'Versión demostrativa';
  static const unavailableConnection =
      'La conexión con este proveedor todavía no está disponible.';

  static String utilityName(UtilityType type) => switch (type) {
    UtilityType.water => 'Agua',
    UtilityType.electricity => 'Electricidad',
  };
}
