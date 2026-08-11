# Plan de implementación: ConsumoPlus 0.2.0 Beta

**Objetivo:** endurecer la versión funcional actual y dejar preparada una cadena
Release firmada, deteniéndose antes de crear la keystore.

**Base verificada:** rama `master`, versión `0.1.0+1`, 243 pruebas aprobadas con
`flutter test --no-pub` el 11 de agosto de 2026.

**Restricciones:** no modificar conectores, parsers, modelos predictivos,
SQLCipher ni funciones de negocio; no generar claves; no publicar; no hacer
commit hasta que el APK Release sea probado manualmente.

## Tarea 1: fijar la privacidad y versión visibles mediante TDD

**Archivos:**

- Modificar `test/features/settings/settings_screen_test.dart`.
- Modificar `lib/app/config/app_copy.dart`.
- Modificar `lib/app/config/app_metadata.dart`.
- Modificar `lib/features/settings/settings_screen.dart`.
- Modificar `pubspec.yaml`.

**Orden:**

1. Añadir pruebas de widget que exijan los siete hechos de privacidad, ausencia
   de controles interactivos engañosos y `Versión 0.2.0 Beta`.
2. Ejecutar la prueba y confirmar que falla por el contenido todavía ausente.
3. Centralizar los textos en `AppCopy`, componerlos con filas informativas y
   retirar el anuncio futuro de Apariencia.
4. Cambiar `pubspec.yaml` a `0.2.0+2` y los metadatos visibles a Beta.
5. Repetir la prueba localizada hasta obtener verde.

**Comando:**

```powershell
flutter test --no-pub test/features/settings/settings_screen_test.dart
```

**Criterio de finalización:** toda la información aprobada es visible, veraz y
no presenta acciones inexistentes.

## Tarea 2: añadir el descargo predictivo mediante TDD

**Archivos:**

- Modificar `test/features/home/presentation/forecast_section_test.dart` o la
  prueba de presentación equivalente existente.
- Modificar `lib/features/home/forecast_copy.dart`.
- Modificar `lib/features/home/presentation/widgets/forecast_section.dart`.
- Modificar únicamente si resulta necesario
  `lib/features/home/presentation/widgets/service_forecast_card.dart`.

**Orden:**

1. Añadir una prueba que renderice pronósticos activos y exija exactamente el
   descargo aprobado una sola vez, incluyendo semántica accesible.
2. Confirmar el fallo por ausencia del texto.
3. Centralizar el descargo en `ForecastCopy` y mostrarlo al pie de la sección.
4. Confirmar que las pruebas pasan sin cambiar cálculos ni modelos.

**Comando:**

```powershell
flutter test --no-pub test/features/home/presentation/forecast_section_test.dart
```

**Criterio de finalización:** el aviso es visible y accesible; las cifras y
reglas predictivas permanecen intactas.

## Tarea 3: limpiar solo textos vigentes obsoletos

**Archivos:**

- Revisar y modificar únicamente `lib/app/config/app_copy.dart`, `README.md` y
  documentos operativos actuales donde exista una afirmación obsoleta.
- No modificar especificaciones o planes históricos archivados.

**Orden:**

1. Buscar menciones de demostración, prototipo, pendiente, no implementado y
   versiones anteriores fuera de documentación histórica.
2. Corregir solo afirmaciones que contradigan el estado funcional probado.
3. Conservar mensajes reales para rutas o proveedores genuinamente no
   disponibles.

**Comando:**

```powershell
rg -n -i "demostr|prototip|pendiente|no implement|0\.1\.0" lib README.md docs -g "!docs/superpowers/**"
```

**Criterio de finalización:** la copia actual no describe como futura una función
ya disponible ni promete capacidades inexistentes.

## Tarea 4: preparar firma Release con fallo seguro

**Archivos:**

- Modificar `android/app/build.gradle.kts`.
- Modificar `.gitignore` y, solo si hace falta, `android/.gitignore`.
- No crear `android/key.properties` ni ninguna keystore.

**Orden:**

1. Cargar propiedades locales desde `android/key.properties` cuando exista.
2. Crear una configuración `release` independiente de `debug`.
3. Validar que una tarea Release sin archivo o campos completos falle con un
   mensaje seguro y accionable.
4. Mantener minificación y reglas ProGuard actuales.
5. Ignorar `/dist/`, `*.aab`, `key.properties`, `*.jks` y `*.keystore`.
6. Verificar los ignorados con rutas ficticias; no crear secretos.

**Comandos:**

```powershell
git check-ignore -v --no-index android/key.properties
git check-ignore -v --no-index android/app/consumoplus-release.jks
git check-ignore -v --no-index dist/consumoplus-0.2.0-beta/app-release.aab
```

**Criterio de finalización:** Release nunca usa la clave debug y los materiales de
firma/distribución no pueden añadirse accidentalmente.

## Tarea 5: actualizar documentación operativa

**Archivos:**

- Modificar `README.md`.
- Modificar `docs/security.md`.
- Crear o modificar una guía Release específica solo si evita sobrecargar README.

**Contenido:** versión Beta, privacidad real, HTTP autorizado, firma local,
comandos futuros de APK universal, split por ABI y AAB, verificación de firma,
icono/splash provisionales y prohibición de versionar artefactos o claves.

**Criterio de finalización:** un desarrollador puede reproducir el flujo sin
interpretar secretos como valores versionables.

## Tarea 6: verificación previa a la keystore

**Orden y comandos:**

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
flutter test --no-pub
git diff --check
git status --short
```

Además, repetir el escaneo redactado de logs, credenciales, cookies, HTML real,
datos personales, bases, claves y artefactos. No imprimir valores sospechosos.

**Criterio de finalización:** formato, análisis y  suite pasan; no hay materiales
sensibles ni artefactos; el único bloqueo de compilación Release es la ausencia
intencional de la clave.

## Tarea 7: detenerse y entregar instrucciones de clave

No ejecutar `keytool`. Informar comando interactivo, ruta externa recomendada,
alias, plantilla de `android/key.properties`, campos manuales, comprobaciones de
Git y respaldo cifrado. Esperar confirmación del usuario.

## Tarea 8: flujo posterior, no ejecutar todavía

Una vez configurada y confirmada la clave:

```powershell
flutter build apk --release
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

Verificar firma Release con `apksigner`, nombre de paquete, versión y SHA-256;
copiar artefactos a `dist/consumoplus-0.2.0-beta/`; crear instrucciones para
testers; probar el APK universal en Android real. Solo después de la aprobación
manual se preparará un commit explícito, sin `git add .`, y posteriormente el tag
propuesto `v0.2.0-beta.1` si el usuario lo autoriza.
