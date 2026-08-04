# ConsumoPlus: diseño de la primera etapa

Fecha: 2026-08-04
Estado: aprobado para implementación

## 1. Propósito

ConsumoPlus será una aplicación móvil Flutter orientada inicialmente a usuarios
de Tacna. Su primera etapa ofrecerá una experiencia demostrativa para explorar
los servicios de agua de EPS Tacna y electricidad de Electrosur. No realizará
conexiones reales ni mostrará datos de consumo.

La arquitectura permitirá incorporar posteriormente otras ciudades y
proveedores sin rehacer la pantalla principal, la navegación compartida ni los
componentes visuales. Esa preparación se limitará a contratos y configuraciones
que la primera etapa utiliza realmente; no se crearán carpetas vacías ni modelos
anticipados.

## 2. Identidad y plataforma

- Proyecto Flutter: `consumo_plus`.
- Nombre visible: `ConsumoPlus`.
- Versión inicial: `0.1.0`.
- Plataforma inicial: Android.
- Lenguaje y framework: Dart, Flutter y Material 3.
- Dirección visual: **Hogar claro**.
- Dependencias: SDK de Flutter únicamente, salvo que una necesidad verificable
  obligue a reconsiderarlo.

## 3. Alcance

### Incluido

- Estructura inicial de un proyecto Flutter.
- Pantalla de carga con inicialización reemplazable, estado de error y reintento.
- Pantalla principal con opciones para Agua y Electricidad.
- Pantalla demostrativa compartida para EPS Tacna y Electrosur.
- Pantalla informativa de Configuración.
- Navegación nativa hacia adelante y hacia atrás.
- Tema, tokens de diseño, textos y configuraciones centralizados.
- Pruebas unitarias y de widgets para estados y navegación.
- README con instrucciones de ejecución y verificación.

### Excluido

- Formularios y captura de credenciales.
- Conexiones con EPS Tacna o Electrosur.
- Scraping, APIs, backend, Firebase o Supabase.
- Base de datos, autenticación o almacenamiento de consumos.
- Gráficos, predicciones, publicidad o datos simulados de consumo.
- Selector de ciudad o proveedor.
- Implementaciones para proveedores distintos de EPS Tacna y Electrosur.
- Interruptores, botones o indicadores que aparenten funciones no disponibles.

## 4. Dirección visual: Hogar claro

La interfaz comunicará tranquilidad doméstica, claridad y confianza. No tendrá
apariencia de dashboard ni empleará métricas, gráficos o estados ficticios.

- Fondo general marfil o gris cálido muy claro.
- Superficies blancas y texto gris azulado oscuro.
- Agua representada con azul medio, azul pálido, gota y formas circulares.
- Electricidad representada con ámbar, crema, rayo y acentos más dinámicos.
- Jerarquía tipográfica clara con la tipografía del sistema.
- Bordes suavemente redondeados y áreas táctiles de al menos 48 píxeles lógicos.
- Sin gradientes, imágenes externas ni decoración sin función.
- Animaciones breves de aparición y pulsación que respeten la preferencia del
  sistema de reducir movimiento.
- Iconos, etiquetas y formas acompañarán siempre al color para distinguir los
  servicios de forma accesible.

La implementación consultará la skill local `design-taste-frontend` y adaptará
sus principios de jerarquía, espaciado, contraste, densidad y movimiento a
Flutter. No se trasladarán patrones web o animaciones que no correspondan al
alcance móvil.

## 5. Sistema de diseño

Los valores reutilizables no se declararán dentro de pantallas o widgets.

- `AppColors`: paleta neutra, colores semánticos y variantes de Agua y
  Electricidad.
- `AppSpacing`: escala pequeña de espacios reutilizables.
- `AppRadii`: radios de superficies, iconos y tarjetas.
- `AppDurations`: duraciones visuales de aparición e interacción.
- `AppTypography`: composición tipográfica basada en Material 3 y la tipografía
  del sistema.
- `AppTheme`: construirá `ThemeData` usando los tokens anteriores; no almacenará
  todas las constantes del proyecto.

La representación visual asociada a `UtilityType` se centralizará en
`UtilityVisualConfig`, dentro de la capa de tema. Esa configuración contendrá
icono, colores y rasgos de forma. Una extensión documentada sobre `UtilityType`
resolverá la configuración con un único `switch`. Las pantallas y widgets no
repetirán condicionales por tipo de servicio.

## 6. Configuración de producto y textos

Los datos configurables se separarán de las pantallas:

- `AppMetadata`: nombre visible y versión.
- `AppCopy`: textos compartidos y mensajes demostrativos.
- `DemoConfig`: duración simulada de arranque y cualquier otro valor estrictamente
  demostrativo que llegue a ser necesario en esta etapa.
- `demoProviders`: identidades constantes de EPS Tacna y Electrosur.
- `UtilityVisualConfig`: iconos y tratamiento visual por `UtilityType`.

Los textos principales de Inicio serán:

- “Explora una forma sencilla de visualizar tus servicios de agua y
  electricidad”.
- “Esta versión demostrativa todavía no se conecta con los proveedores”.

Las cadenas específicas de un proveedor estarán en su configuración o en la
configuración demostrativa correspondiente, no duplicadas en pantallas.

## 7. Modelos y límites

### `UtilityType`

Enumera `water` y `electricity`. No contiene navegación ni información de un
proveedor concreto.

### `ProviderIdentity`

Modelo tipado, inmutable y construible con `const`. Contiene únicamente:

- Identificador estable.
- Nombre visible.
- Localidad o área de servicio.
- `UtilityType`.
- Descripción demostrativa específica del proveedor.

No contiene rutas, callbacks, colores, iconos, widgets ni lógica de conexión.

### Conceptos diferidos

`ServiceProvider`, `ProviderConnection` y `ConsumptionRecord` no se crearán en
esta etapa. Se incorporarán cuando exista una conexión o un registro real que
justifique sus contratos. La separación actual entre identidad, presentación y
navegación deja el punto de extensión necesario sin anticipar implementaciones.

## 8. Inicialización

`StartupService` expondrá una operación asíncrona `initialize`. La implementación
`DemoStartupService` simulará una inicialización breve fuera de la interfaz y
permitirá inyectar su duración para que las pruebas no esperen tiempo real.

`StartupController` recibirá `StartupService` mediante el constructor y será el
único responsable de administrar estos estados:

- `idle`.
- `initializing`.
- `success`.
- `failure`, con información presentable del error.

El controlador ofrecerá `initialize` y `retry`, evitará ejecuciones simultáneas y
notificará cambios. No conocerá `BuildContext`, rutas ni `Navigator`.

`SplashScreen` dependerá solo de `StartupController`. Observará sus estados,
iniciará el proceso una vez y, al recibir `success`, ejecutará un reemplazo de
ruta hacia Inicio. El botón Reintentar llamará a `retry` y será visible únicamente
en el estado de error.

El propietario del controlador será la composición superior de la aplicación,
que también será responsable de liberarlo.

## 9. Navegación

La aplicación utilizará `MaterialApp` y navegación nativa mediante rutas
nombradas generadas centralmente por `AppRouter`.

```text
Inicio de la aplicación
        |
        v
SplashScreen
        | pushReplacementNamed
        v
HomeScreen
        |-- ProviderPlaceholderScreen(EPS Tacna) -- back --> HomeScreen
        |-- ProviderPlaceholderScreen(Electrosur) -- back --> HomeScreen
        `-- SettingsScreen ------------------------ back --> HomeScreen
```

La ruta de proveedor recibirá un `ProviderIdentity` tipado. El router validará
el argumento antes de construir la pantalla. Los modelos no conocerán las rutas.

El reemplazo al finalizar la carga garantiza que Splash no reaparezca al
presionar Atrás.

## 10. Composición de pantallas

### SplashScreen

- Fondo neutro.
- `BrandMark` centrado con gota y rayo de Material.
- Nombre `ConsumoPlus`.
- Texto “Agua y electricidad, en un solo lugar”.
- Indicador discreto sin porcentaje simulado.
- Aparición suave de marca y texto.
- Estado de error con mensaje claro y botón Reintentar funcional.

### HomeScreen

- `SafeArea` y contenido desplazable para pantallas pequeñas.
- Encabezado con marca y botón real hacia Configuración.
- Mensaje de bienvenida.
- Texto principal y advertencia demostrativa definidos en `AppCopy`.
- Lista vertical de `UtilityServiceCard` creada desde `demoProviders`.
- Tarjeta Agua con EPS Tacna y configuración visual azul.
- Tarjeta Electricidad con Electrosur y configuración visual ámbar.

La lista basada en identidades permite sustituir o ampliar proveedores en una
etapa futura sin reescribir las tarjetas ni la pantalla.

### ProviderPlaceholderScreen

- Barra superior y navegación de regreso.
- Icono y colores resueltos desde `ProviderIdentity.utilityType`.
- Tipo de servicio, proveedor y localidad recibidos mediante
  `ProviderIdentity`.
- Etiqueta textual “Versión demostrativa”.
- Mensaje específico que indica que la conexión no está implementada.
- Sin formularios, credenciales, botones de conexión ni datos de consumo.

### SettingsScreen

- Barra superior y regreso.
- Fila informativa “Apariencia” con disponibilidad futura.
- Fila informativa “Privacidad y almacenamiento local”.
- Versión `0.1.0`.
- Sin `Switch`, casillas, botones, flechas o controles que sugieran acciones no
  disponibles.

## 11. Componentes

- `ConsumoPlusApp`: composición principal y ciclo de vida del controlador.
- `AppRouter`: creación y validación de rutas.
- `StartupService` y `DemoStartupService`: inicialización reemplazable.
- `StartupController`: máquina de estados y reintento.
- `BrandMark`: identidad provisional con iconos Material.
- `UtilityServiceCard`: opción accesible y reutilizable de servicio.
- `ProviderPlaceholderScreen`: vista común basada en `ProviderIdentity`.
- `SettingsInfoRow`: contenido estático que no aparenta interacción.

Estructura objetivo:

```text
lib/
  main.dart
  app/
    app.dart
    config/
      app_copy.dart
      app_metadata.dart
    routes/
      app_router.dart
      app_routes.dart
    theme/
      app_colors.dart
      app_durations.dart
      app_radii.dart
      app_spacing.dart
      app_theme.dart
      app_typography.dart
      utility_visual_config.dart
  core/
    config/
      demo_config.dart
      demo_providers.dart
    models/
      provider_identity.dart
      utility_type.dart
    startup/
      startup_controller.dart
      startup_service.dart
      demo_startup_service.dart
  features/
    splash/
      splash_screen.dart
    home/
      home_screen.dart
    provider/
      provider_placeholder_screen.dart
    settings/
      settings_screen.dart
  shared/
    widgets/
      brand_mark.dart
      settings_info_row.dart
      utility_service_card.dart
```

## 12. Flujo de datos

1. `main` crea `DemoStartupService` y arranca `ConsumoPlusApp`.
2. La aplicación crea y conserva `StartupController`.
3. `SplashScreen` observa el controlador y reemplaza su ruta cuando el estado es
   `success`.
4. `HomeScreen` recibe las identidades de `demoProviders` y genera las tarjetas.
5. Al pulsar una tarjeta, `AppRouter` recibe su `ProviderIdentity` y construye
   `ProviderPlaceholderScreen`.
6. Los widgets obtienen la presentación desde `UtilityVisualConfig`, no desde el
   modelo de proveedor.

## 13. Accesibilidad y adaptación

- `SafeArea` en las pantallas principales.
- Contenido desplazable y flexible para evitar desbordamientos.
- Compatibilidad con escalado de texto del sistema.
- Contraste suficiente para texto e iconos.
- Semántica y tooltips en botones e iconos interactivos.
- Objetivos táctiles mínimos de 48 píxeles lógicos.
- No depender exclusivamente del color.
- Respetar `MediaQuery.disableAnimations` cuando corresponda.

## 14. Manejo de errores

- Los errores de inicialización se convierten en estado `failure` dentro de
  `StartupController`.
- Splash muestra un mensaje comprensible y un único botón Reintentar.
- Reintentar inicia una nueva ejecución real del servicio.
- Los errores de argumentos de ruta producen una pantalla controlada de ruta no
  disponible durante desarrollo, no una excepción sin manejar.
- No habrá estados de error de proveedores porque esta etapa no intenta
  conectarse a ellos.

## 15. Estrategia de pruebas

### Unitarias

- `ProviderIdentity` conserva correctamente sus datos inmutables.
- `StartupController` recorre `idle`, `initializing` y `success`.
- Un fallo del servicio produce `failure`.
- `retry` invoca realmente el servicio otra vez y puede llegar a `success`.
- El controlador evita inicializaciones simultáneas.

### Widgets y navegación

- Splash muestra carga y reemplaza su ruta después del éxito.
- Atrás desde Inicio no vuelve a Splash.
- El estado de error presenta Reintentar y el botón funciona.
- Inicio muestra textos demostrativos y las dos tarjetas.
- Agua abre la pantalla con los datos de EPS Tacna.
- Electricidad abre la pantalla con los datos de Electrosur.
- `ProviderPlaceholderScreen` representa cualquier `ProviderIdentity` recibido.
- Configuración abre y regresa correctamente.
- Configuración no contiene interruptores ni controles engañosos.
- Las pantallas críticas renderizan en una dimensión pequeña y con texto
  ampliado sin desbordamientos.

## 16. Verificación

Antes de finalizar se ejecutarán:

```text
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

También se inspeccionarán imports innecesarios, rutas, semántica y el flujo
manual o automatizado Splash → Inicio → Agua/Electricidad/Configuración → Atrás.

## 17. Criterios de finalización

- El proyecto Flutter puede compilarse para Android en el entorno disponible.
- La carga, el error y el reintento funcionan mediante `StartupController`.
- Splash se elimina del historial al entrar en Inicio.
- La pantalla principal refleja Hogar claro y distingue ambos servicios.
- Las pantallas de proveedor reciben un `ProviderIdentity` tipado.
- Configuración es informativa y no contiene controles falsos.
- Los tokens, textos y proveedores demostrativos están centralizados.
- No se implementa ninguna conexión, formulario, base de datos o dato de consumo.
- `flutter analyze` finaliza sin errores.
- Todas las pruebas finalizan correctamente.
- La compilación Android de depuración finaliza correctamente cuando el SDK del
  entorno lo permite.
- El README explica cómo ejecutar y verificar la aplicación.
