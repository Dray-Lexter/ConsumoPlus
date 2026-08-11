# ConsumoPlus

Aplicación Flutter local-first para consultar servicios domésticos en Tacna. La versión `0.2.0 Beta` integra Agua con EPS Tacna, Electricidad con Electrosur, próximas fechas y rangos orientativos de consumo e importe.

## Servicios disponibles

- La consulta se inicia manualmente y exige autorización explícita porque ambos portales usan HTTP.
- Las claves y cookies existen solo en memoria durante cada sincronización.
- El usuario de EPS Tacna y el contrato de Electrosur pueden recordarse; las claves no.
- Estado de cuenta, consumos, recibos, pagos, suministro y metadatos se guardan en una única base SQLCipher.
- Al reabrir un módulo, la aplicación muestra primero la copia local sin usar la red.
- Una descarga parcial o fallida conserva los datos validados anteriormente.
- La eliminación es independiente: Agua nunca borra Electricidad y viceversa.
- Inicio calcula localmente rangos orientativos del consumo y del importe del siguiente mes para cada suministro activo, cuando existe historial suficiente.

En EPS Tacna, los datos del suministro se extraen del bloque informativo de Facturación. En Electrosur, contrato, titular, dirección y tarifa se obtienen de Estado de Cuenta, y los campos secundarios se combinan desde Suministro. Un campo opcional ausente se muestra como `No disponible en el portal` sin invalidar las demás secciones.

## Seguridad importante

Android bloquea HTTP globalmente. La configuración autoriza cleartext únicamente a `oficinavirtual.epstacna.com.pe` y `www.electrosur.com.pe`. ConsumoPlus no incluye backend, nube propia para el historial, analítica ni telemetría. Las contraseñas no se almacenan y las cookies de sesión existen únicamente durante cada sincronización. Las integraciones dependen de las condiciones de seguridad de los proveedores y actualmente ambas requieren autorización explícita para usar HTTP.

Consulta [seguridad](docs/security.md), [pronóstico local](docs/forecasting.md), [preparación Release Android](docs/release_android.md), [conector EPS Tacna](docs/eps_tacna_connector.md) y [conector Electrosur](docs/electrosur_connector.md).

## Ejecutar y verificar

Requiere Flutter 3.44.8/Dart 3.12.2, Java 17 y Android SDK configurado.

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`.

Los artefactos Release exigen una keystore privada y `android/key.properties`; nunca usan la clave debug. Icono y splash conservan provisionalmente los recursos predeterminados de Flutter hasta recibir la marca definitiva.

## Estructura

```text
lib/
  app/                         rutas, tema, composición y producto
  core/data/local/             esquema SQLCipher y clave compartida
  features/water/              módulo EPS Tacna
  features/electricity/        módulo Electrosur
    application/               ViewModel, estado y dependencias
    domain/                    modelos, errores y repositorio
    data/parsers/              HTML sanitizado a modelos tipados
    data/remote/               HTTP y sesión efímera
    data/local/                tablas y persistencia
    data/repositories/         sincronización local-first
    presentation/              pantallas Material 3
  features/home/               fechas próximas y pronóstico matemático local
test/                          unitarias, widgets, seguridad y fixtures ficticios
```

No se deben usar credenciales ni datos personales reales en pruebas, fixtures, capturas, commits o documentación. La prueba del portal real se realiza únicamente en un teléfono controlado, ingresando las credenciales directamente.
