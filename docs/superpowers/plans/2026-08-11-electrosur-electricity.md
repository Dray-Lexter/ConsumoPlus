# Plan de implementación: Electricidad / Electrosur

> Ejecución inline mediante `superpowers:executing-plans` y TDD. Por instrucción del usuario no se usan subagentes ni se crean commits.

**Objetivo:** añadir Electrosur local-first con sesión efímera, parsers tolerantes, persistencia SQLCipher compartida y una interfaz Material 3 coherente con Agua.

**Contrato:** [especificación de Electricidad](../specs/2026-08-11-electrosur-electricity-design.md).

## 1. Modelos y errores

**Crear:** `lib/features/electricity/domain/models/*.dart`, `lib/features/electricity/domain/errors/electricity_exceptions.dart`.
**Pruebas:** `test/features/electricity/domain/electricity_models_test.dart`.

- Escribir primero pruebas de invariantes, opcionalidad y snapshot.
- Implementar modelos `const`, tipados e inmutables, estados de sincronización y excepciones con códigos sanitizados.
- Verificar: `flutter test test/features/electricity/domain/electricity_models_test.dart`.

## 2. Parsers sanitizados

**Crear:** `lib/features/electricity/data/parsers/*.dart`, fixtures en `test/fixtures/electrosur/`, `test/features/electricity/data/parsers/electrosur_parsers_test.dart`.

- Probar formulario de login, EstadoCuenta, Consumos, Pagos, Suministro, columnas reordenadas, campos opcionales, fechas, periodo `YYYYMM`, kWh→Wh e importes con cuatro decimales.
- Implementar un normalizador compartido del módulo y parsers por sección.
- Verificar: `flutter test test/features/electricity/data/parsers/electrosur_parsers_test.dart`.

## 3. Base compartida y migración

**Crear:** `lib/core/data/local/app_database_schema.dart`, `lib/core/data/local/encrypted_app_database.dart`, almacenamiento seguro compartido; `lib/features/electricity/data/local/electricity_database_schema.dart`.
**Modificar:** dependencias/importaciones locales de Agua sin cambiar sus modelos ni pantallas; `lib/features/water/data/local/water_database_schema.dart`.
**Pruebas:** `test/core/data/local/app_database_migration_test.dart`.

- Probar en rojo creación limpia v2 y migración v1→v2 con filas de Agua preservadas.
- Implementar `onUpgrade` acotado y mantener el nombre físico de la base existente.
- Verificar: `flutter test test/core/data/local/app_database_migration_test.dart`.

## 4. Persistencia de Electricidad

**Crear:** `lib/features/electricity/data/local/electricity_local_data_source.dart`; `test/features/electricity/data/local/electricity_local_data_source_test.dart`.

- Probar persistencia atómica, lectura local, upsert, conteos, ausencia de duplicados, conservación ante falla y eliminación aislada.
- Ajustar `EpsTacnaRepository.deleteWaterData` para no borrar base/clave compartidas y agregar regresión de aislamiento Agua/Electricidad.
- Verificar las pruebas locales de ambos módulos.

## 5. Cliente HTTP y fuente remota

**Crear:** `lib/features/electricity/data/remote/*.dart`; `test/features/electricity/data/remote/electrosur_remote_test.dart`.
**Modificar:** `android/app/src/main/res/xml/network_security_config.xml`, prueba de seguridad Android.

- Probar POST exacto, formulario, 302, `Location`, `.ASPXAUTH`, ausencia de cookie, redirección/login, orden de GET y destrucción de sesión en éxito y falla.
- Implementar transporte `dart:io` sin logs ni persistencia de cookies.
- Permitir cleartext únicamente al host exacto Electrosur, conservando EPS.
- Verificar pruebas remotas y `test/security/android_security_config_test.dart`.

## 6. Repositorio y ViewModel

**Crear:** `lib/features/electricity/domain/repositories/electricity_repository.dart`, `lib/features/electricity/data/repositories/electrosur_repository.dart`, `lib/features/electricity/application/*.dart`; pruebas correspondientes.

- Probar local-first, sincronización, resumen de cambios, errores tipados, recomendación mensual y eliminación exclusiva.
- Implementar composición remota/local y recordar solo el contrato.
- Verificar pruebas de repositorio y ViewModel.

## 7. Composición de dependencias y navegación

**Crear:** `lib/core/data/local/app_local_dependencies.dart`, `lib/features/electricity/application/electricity_dependencies.dart`.
**Modificar:** `lib/app/app.dart`, `lib/app/routes/app_router.dart`, `lib/app/routes/app_routes.dart`, `lib/features/water/application/water_dependencies.dart`.

- Compartir una instancia de base/clave segura entre módulos.
- Enrutar la identidad tipada de Electrosur a `ElectricityScreen` y conservar EPS Tacna.
- Probar navegación de ambos proveedores.

## 8. Interfaz Electricidad

**Crear:** `lib/features/electricity/presentation/` con pantalla, copia, formateadores, resumen, formulario y cuatro pantallas de detalle.
**Reutilizar:** tokens `AppColors`, `AppSpacing`, `AppRadii`, `AppTypography` y configuración visual de `UtilityType`.

- Probar primero estado vacío, sincronización/error, resumen y detalles.
- Implementar Material 3 ámbar, sin dirección/medidor completos en resumen y sin acciones ficticias.
- Probar pantalla pequeña, texto ampliado, targets táctiles y etiquetas semánticas.

## 9. Documentación y pruebas de seguridad

**Modificar solo lo afectado:** `README.md`, `docs/architecture.md`, `docs/data_dictionary.md`, `docs/security.md`; crear `docs/electrosur_connector.md`.

- Documentar contrato sanitizado, migración, tablas, aislamiento y limitaciones.
- Extender el escaneo de secretos/fixtures y comprobar ausencia de valores reales.
- Ejecutar todas las pruebas dirigidas de Electricidad y regresiones de Agua.

## 10. Verificación final

Ejecutar, en este orden:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git diff --check
flutter build apk --debug
```

**Finalización:** cero errores de formato/análisis/diff, suite completa aprobada, un único APK debug existente y reporte de limitaciones/pasos manuales. No commit, merge ni push.
