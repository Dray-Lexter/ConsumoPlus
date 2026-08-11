# Preparación Release Android

## Estado de la beta

- Nombre visible: ConsumoPlus.
- Paquete: `pe.consumoplus.consumo_plus`.
- Versión: `0.2.0+2`; texto visible: `0.2.0 Beta`.
- SDK mínimo 24; SDK objetivo y de compilación 36 con Flutter 3.44.8.
- R8/minificación permanece activo con las reglas SQLCipher existentes.
- Icono y splash: recursos predeterminados de Flutter, provisionales hasta recibir la marca definitiva.

## Firma local

`android/app/build.gradle.kts` lee `android/key.properties` únicamente desde el equipo local. Una tarea Release falla si falta el archivo o alguno de estos campos:

```properties
storeFile=D:\\Desarrollo\\keys\\consumoplus-release.jks
storePassword=<INTRODUCIR_LOCALMENTE>
keyAlias=consumoplus
keyPassword=<INTRODUCIR_LOCALMENTE>
```

No se deben copiar contraseñas a documentación, código, comandos, capturas o Git. La clave debug no es válida como firma Release definitiva.

## Compilaciones posteriores a configurar la clave

Ejecutar desde la raíz del proyecto:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

Los comandos de empaquetado Release deben ejecutarse sin `--no-pub`. Flutter
necesita regenerar el registro nativo excluyendo plugins de desarrollo como
`integration_test`; reutilizar un registro generado por pruebas puede romper la
compilación Release.

La ruta de trabajo actual es suficientemente larga para que `apkanalyzer`
pueda devolver `AccessDeniedException` al validar un AAB ya generado. El
mensaje genérico de Flutter sobre símbolos no demuestra por sí solo que el
bundle sea inválido: se debe comprobar el código de salida de `apkanalyzer files
list`, la presencia de `libapp.so.sym` y `libflutter.so.sym`, y la firma con
`jarsigner`. Para compilaciones reproducibles posteriores conviene usar la ruta
corta prevista `D:\Proyectos\ConsumoPlus`; este flujo no mueve el proyecto
automáticamente.

Salidas esperadas:

- Universal: `build/app/outputs/flutter-apk/app-release.apk`.
- Por ABI: `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk` y `app-x86_64-release.apk`.
- Bundle: `build/app/outputs/bundle/release/app-release.aab`.

## Verificación posterior

Usar las herramientas del SDK configurado y comparar el certificado del APK con el certificado de la keystore:

```powershell
& "D:\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --verbose --print-certs "build\app\outputs\flutter-apk\app-release.apk"
& "D:\Local\Android\Sdk\cmdline-tools\latest\bin\apkanalyzer.bat" manifest application-id "build\app\outputs\flutter-apk\app-release.apk"
& "D:\Local\Android\Sdk\cmdline-tools\latest\bin\apkanalyzer.bat" manifest version-name "build\app\outputs\flutter-apk\app-release.apk"
& "D:\Local\Android\Sdk\cmdline-tools\latest\bin\apkanalyzer.bat" manifest version-code "build\app\outputs\flutter-apk\app-release.apk"
Get-FileHash "build\app\outputs\flutter-apk\app-release.apk" -Algorithm SHA256
```

El certificado debe coincidir con la clave privada creada para ConsumoPlus y no con Android Debug. Los artefactos se copiarán posteriormente a `dist/consumoplus-0.2.0-beta/`; ese directorio completo está excluido de Git.

## Git y respaldo

Comprobar los ignorados antes de crear o copiar materiales privados:

```powershell
git check-ignore -v --no-index android/key.properties
git check-ignore -v --no-index android/app/consumoplus-release.jks
git check-ignore -v --no-index dist/consumoplus-0.2.0-beta/app-release.aab
```

La keystore y sus contraseñas son necesarias para actualizar la aplicación firmada. Debe conservarse una copia cifrada fuera del equipo de desarrollo y probarse periódicamente que puede recuperarse. Nunca debe almacenarse en el repositorio ni enviarse junto con un APK.
