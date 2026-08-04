# ConsumoPlus

ConsumoPlus es una demostración móvil para hogares de Tacna que presenta, en
un solo lugar, los servicios de agua de EPS Tacna y electricidad de
Electrosur. La versión actual permite recorrer la experiencia y reconocer a
cada proveedor; no consulta cuentas, consumos ni datos reales y todavía no se
conecta con los proveedores.

## Estado y versión

- Versión de la aplicación: `0.1.0` (`0.1.0+1` en `pubspec.yaml`).
- Estado: demostración local de la primera etapa.
- Proveedores incluidos: EPS Tacna (agua) y Electrosur (electricidad), ambos
  para Tacna.
- Interfaz: Flutter Material 3, optimizada para móvil y texto ampliado.

## Requisitos

- Flutter estable compatible con Dart `>=3.12.2 <4.0.0`. El proyecto se
  verifica con Flutter `3.44.8` y Dart `3.12.2`.
- Para ejecutar o compilar Android: Android SDK configurado y una cadena de
  herramientas Java/Android compatible con Flutter (Java 17 para este
  proyecto).
- Un emulador o dispositivo Android disponible para `flutter run`.

Comprueba la instalación con:

```powershell
flutter doctor
flutter --version
```

## Preparación y ejecución

Desde la raíz del proyecto:

```powershell
flutter pub get
flutter run
```

La aplicación muestra una introducción breve, las dos tarjetas de proveedor,
pantallas informativas de demostración y una pantalla estática de
configuración.

## Verificación local

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

El APK de depuración, cuando el Android SDK está disponible y la compilación
termina correctamente, se genera en
`build/app/outputs/flutter-apk/app-debug.apk`.

## Rutas implementadas

| Ruta | Pantalla | Comportamiento |
| --- | --- | --- |
| `/` | Inicio | Prepara la demostración y reemplaza la ruta por `/home` al finalizar. |
| `/home` | Hogar | Presenta EPS Tacna, Electrosur y el acceso a configuración. |
| `/provider` | Proveedor | Requiere un `ProviderIdentity` tipado y muestra su contenido demostrativo. |
| `/settings` | Configuración | Muestra información estática de apariencia, privacidad y versión. |

Una ruta desconocida o `/provider` sin un `ProviderIdentity` válido muestra
`Ruta no disponible`.

## Alcance y no objetivos

Esta etapa no incluye:

- autenticación, cuentas de usuario ni selección de ciudad;
- conexión con EPS Tacna, Electrosur o servicios web;
- lecturas, recibos, pagos, métricas, gráficos o estados de consumo;
- almacenamiento local o remoto;
- controles que simulen apariencia, privacidad o conexiones todavía no
  implementadas.

## Estructura y límites

```text
lib/
├── app/                 # Aplicación, rutas, tema, textos y metadatos
├── core/
│   ├── config/          # Configuración y proveedores de la demostración
│   ├── models/          # Identidad tipada y tipo de servicio
│   └── startup/         # Contrato, servicio y controlador de inicio
├── features/            # Splash, hogar, proveedor y configuración
├── shared/widgets/      # Marca, tarjeta de servicio y filas informativas
└── main.dart            # Composición de la demostración
test/                    # Pruebas unitarias, de widgets y accesibilidad
```

`StartupController` contiene el estado y la coordinación del inicio. Depende
del contrato `StartupService`, evita inicializaciones simultáneas y ofrece el
reintento; la pantalla de inicio observa el controlador y no conoce la
implementación concreta del servicio.

`ProviderIdentity` es el modelo inmutable y tipado que lleva la identidad, la
localidad, el tipo de servicio y el texto demostrativo de cada proveedor. No
contiene navegación ni decisiones visuales: las rutas consumen el modelo y la
configuración visual de agua/electricidad se resuelve de forma centralizada a
partir de `UtilityType`.
