# Plan de implementacion: Agua con EPS Tacna

> Este plan se ejecuta en `feature/eps-tacna-water` con TDD. No se crea commit
> final ni se integra a `master` antes de instalar y probar el APK en telefono.
> `.agents/` permanece sin modificar y sin seguimiento.

**Objetivo:** implementar el modulo Agua local-first, con conexion directa al
portal EPS Tacna, base SQLCipher, clave en Android Keystore, cookies y
contrasena solo en memoria, interfaz Material 3 "Hogar claro" y pruebas sin
acceso al portal real.

**Stack:** Flutter 3.44.8, Dart 3.12.2, Material 3, `dart:io HttpClient`,
`html`, `sqflite_sqlcipher`, `flutter_secure_storage` y
`sqflite_common_ffi` solo para pruebas de SQL.

## Reglas de ejecucion

- Escribir primero la prueba que falla, ejecutarla, implementar el minimo y
  volver a ejecutarla.
- No conectar pruebas automaticas al portal real.
- No imprimir requests, responses, cookies, claves ni credenciales.
- No guardar la contrasena en estado persistente ni dentro de modelos.
- No inventar campos que el portal no expone.
- Ejecutar `git diff --check` y revisar `git status --short` tras cada tarea.
- No agregar `.agents/` a ningun comando Git.

## Tarea 1: dependencias y contratos de dominio

**Archivos:**

- Modificar `pubspec.yaml` y `pubspec.lock`.
- Crear `lib/features/water/domain/models/water_account.dart`.
- Crear `lib/features/water/domain/models/billing_record.dart`.
- Crear `lib/features/water/domain/models/payment_record.dart`.
- Crear `lib/features/water/domain/models/synchronization_metadata.dart`.
- Crear `lib/features/water/domain/models/water_snapshot.dart`.
- Crear `lib/features/water/domain/errors/water_exceptions.dart`.
- Crear `lib/features/water/domain/repositories/water_repository.dart`.
- Crear pruebas equivalentes bajo `test/features/water/domain/`.

**Responsabilidad:** modelos inmutables, dinero en centimos, claves naturales,
estado de sincronizacion y contrato reemplazable del repositorio.

**Ciclo TDD:**

1. Probar construccion, igualdad util mediante claves, orden cronologico,
   opcionalidad de campos no expuestos y codigos de error sanitizados.
2. Ejecutar las pruebas y confirmar fallo por archivos ausentes.
3. Agregar versiones compatibles:
   `html`, `sqflite_sqlcipher`, `flutter_secure_storage` y
   `sqflite_common_ffi` como dev dependency.
4. Implementar modelos const sin mapas dinamicos en el dominio.
5. Ejecutar pruebas de dominio.

**Comandos:**

```powershell
flutter pub get
flutter test test/features/water/domain
dart format lib/features/water/domain test/features/water/domain
git diff --check
```

**Finalizacion:** dependencias resueltas; modelos exactos; ningun `double` para
dinero; todos los campos de perfil no disponibles son nullable y no se
rellenan con texto inventado.

## Tarea 2: normalizacion y parsers HTML sanitizados

**Archivos:**

- Crear `lib/features/water/data/parsers/portal_text_parser.dart`.
- Crear `lib/features/water/data/parsers/session_page_parser.dart`.
- Crear `lib/features/water/data/parsers/account_parser.dart`.
- Crear `lib/features/water/data/parsers/billing_parser.dart`.
- Crear `lib/features/water/data/parsers/payment_parser.dart`.
- Crear fixtures minimos en `test/fixtures/eps_tacna/`.
- Crear pruebas en `test/features/water/data/parsers/`.

**Responsabilidad:** transformar HTML en modelos tipados, localizar columnas
por encabezado normalizado, detectar login/sesion vencida y rechazar cambios
estructurales.

**Fixtures:**

- `authenticated_shell.html`
- `login_form.html`
- `billing_history.html`
- `billing_history_second_visual_page.html`, si se necesita demostrar que el
  HTML ya contiene todas las filas
- `payment_history.html`
- `missing_headers.html`

Todos usan nombres, codigos, recibos, fechas y montos ficticios evidentes.

**Ciclo TDD:**

1. Probar meses en espanol, fechas, `S/` a centimos, espacios y mayusculas.
2. Probar encabezados reordenados y filas completas.
3. Probar que todas las filas del HTML se parsean sin parametros de pagina.
4. Probar tabla ausente, encabezado faltante y formulario de login.
5. Implementar la minima logica y volver a verde.

**Comandos:**

```powershell
flutter test test/features/water/data/parsers
dart format lib/features/water/data/parsers test/features/water/data/parsers
rg -n "POZO|SUAREZ|TULA|S/ [0-9]" test/fixtures
git diff --check
```

**Finalizacion:** parsers por encabezado, errores tipados y fixtures sin datos
reales; Facturacion procesa todas las filas de una respuesta.

## Tarea 3: HTTP, cookies en memoria y fuente remota

**Archivos:**

- Crear `lib/features/water/data/remote/eps_tacna_endpoints.dart`.
- Crear `lib/features/water/data/remote/portal_request.dart`.
- Crear `lib/features/water/data/remote/portal_response.dart`.
- Crear `lib/features/water/data/remote/eps_tacna_transport.dart`.
- Crear `lib/features/water/data/remote/io_eps_tacna_transport.dart`.
- Crear `lib/features/water/data/remote/in_memory_cookie_jar.dart`.
- Crear `lib/features/water/data/remote/eps_tacna_http_client.dart`.
- Crear `lib/features/water/data/remote/eps_tacna_remote_data_source.dart`.
- Crear fakes y pruebas bajo `test/features/water/data/remote/`.

**Responsabilidad:** restringir host/esquema, aplicar timeout, controlar
redirecciones, manejar cookies tipadas solo en memoria, autenticar y descargar
shell, facturacion y pagos.

**Ciclo TDD:**

1. Probar endpoints exactos observados y rechazo de cualquier otro host.
2. Probar login correcto con transporte falso y senal de `main.php`.
3. Probar login sin senal autenticada, sin incluir body en la excepcion.
4. Probar captura, envio y destruccion de cookies sin serializacion.
5. Probar sesion vencida, timeout, portal no disponible y cierre en `finally`.
6. Probar POST sin parametros a `ctacte.php` e `historialpagos.php`.
7. Implementar con `dart:io HttpClient` sin interceptores de logging.

**Comandos:**

```powershell
flutter test test/features/water/data/remote
dart format lib/features/water/data/remote test/features/water/data/remote
rg -n "print\(|debugPrint|response.body|document.cookie|CookieJar" lib/features/water
git diff --check
```

**Finalizacion:** cliente cerrable y cancelable; cookies solo en memoria;
ningun body sensible en errores; solo dominio EPS por HTTP.

## Tarea 4: clave segura y base SQLCipher

**Archivos:**

- Crear `lib/features/water/data/local/database_key_store.dart`.
- Crear `lib/features/water/data/local/secure_database_key_store.dart`.
- Crear `lib/features/water/data/local/water_database_schema.dart`.
- Crear `lib/features/water/data/local/encrypted_water_database.dart`.
- Crear `lib/features/water/data/local/water_local_data_source.dart`.
- Crear pruebas en `test/features/water/data/local/`.

**Responsabilidad:** generar clave con `Random.secure`, almacenarla mediante
`flutter_secure_storage`, abrir SQLCipher con password, crear esquema version
1, hacer transacciones y upsert.

**Esquema version 1:**

- `water_accounts`
- `billing_records`
- `payment_records`
- `synchronization_metadata`

Indices unicos:

- billing: `provider_id, customer_code, receipt_number`;
- payments: `provider_id, customer_code, receipt_number, payment_date,
  amount_cents`;
- account y metadata: `provider_id, customer_code`.

**Ciclo TDD:**

1. Probar generacion unica, lectura y borrado de clave con storage falso.
2. Probar DDL, version y restricciones con `sqflite_common_ffi`.
3. Probar upsert sin duplicado y actualizacion de deuda, total y atraso.
4. Probar transaccion atomica y conservacion ante fallo.
5. Probar reapertura de base de prueba y persistencia.
6. Implementar adaptador SQLCipher de produccion con password obligatorio.

**Comandos:**

```powershell
flutter test test/features/water/data/local
dart format lib/features/water/data/local test/features/water/data/local
rg -n "openDatabase" lib/features/water/data/local
git diff --check
```

**Finalizacion:** no existe ruta de produccion que abra la base sin password;
upsert y borrado por proveedor probados; la clave no aparece en logs ni SQL.

## Tarea 5: repositorio y sincronizacion local-first

**Archivos:**

- Crear `lib/features/water/data/repositories/eps_tacna_repository.dart`.
- Crear `lib/features/water/domain/models/synchronization_result.dart`.
- Crear pruebas en `test/features/water/data/repositories/`.

**Responsabilidad:** leer snapshot local, coordinar sesion remota, validar
descarga completa y persistir todo de forma atomica.

**Ciclo TDD:**

1. Probar lectura local sin llamar al remoto.
2. Probar sincronizacion completa, conteos insertados/actualizados y metadata.
3. Probar segunda sincronizacion sin duplicados.
4. Probar fallo de pagos despues de facturacion y conservacion del snapshot.
5. Probar solicitud de logout y destruccion de cookies en exito/error.
6. Probar borrado aislado de Agua y usuario recordado.
7. Implementar orquestacion minima.

**Comandos:**

```powershell
flutter test test/features/water/data/repositories
dart format lib/features/water/data/repositories test/features/water/data/repositories
git diff --check
```

**Finalizacion:** politica local-first y sincronizacion atomica verificadas;
fallos nunca borran ni reemplazan datos validos.

## Tarea 6: ViewModel, estados y composicion de dependencias

**Archivos:**

- Crear `lib/features/water/application/water_state.dart`.
- Crear `lib/features/water/application/water_view_model.dart`.
- Crear `lib/features/water/application/water_dependencies.dart`.
- Crear `lib/features/water/application/password_request.dart`.
- Modificar `lib/main.dart`.
- Modificar `lib/app/app.dart`.
- Crear pruebas en `test/features/water/application/`.

**Responsabilidad:** cargar local al abrir, representar empty/loading/data/error,
pedir contrasena solo al usuario, limpiar valores efimeros y exponer eventos
para UI sin HTTP/SQL.

**Ciclo TDD:**

1. Probar carga local inmediata y cero scraping automatico.
2. Probar login/actualizacion solo tras password explicita.
3. Probar limpieza de password en exito, error y dispose.
4. Probar usuario recordado editable.
5. Probar mensaje de resultado con conteos.
6. Probar recomendacion de actualizar al cambiar el mes.
7. Implementar ViewModel y composicion por constructores.

**Comandos:**

```powershell
flutter test test/features/water/application
dart format lib/features/water/application test/features/water/application lib/main.dart lib/app/app.dart
git diff --check
```

**Finalizacion:** ViewModel no conserva password tras una operacion y abrir
Agua nunca inicia red por si solo.

## Tarea 7: rutas y pantalla Agua sin datos

**Archivos:**

- Modificar `lib/app/routes/app_routes.dart`.
- Modificar `lib/app/routes/app_router.dart`.
- Crear `lib/features/water/presentation/water_screen.dart`.
- Crear `lib/features/water/presentation/widgets/http_risk_notice.dart`.
- Crear `lib/features/water/presentation/widgets/water_login_form.dart`.
- Modificar textos/tokens en `lib/app/config/` y `lib/app/theme/`.
- Modificar `lib/features/home/home_screen.dart` solo si la integracion lo
  exige.
- Crear pruebas en `test/features/water/presentation/water_login_test.dart` y
  actualizar navegacion Home.

**Responsabilidad:** reemplazar solo Agua; Electrosur conserva placeholder.
Formulario accesible, aviso HTTP, autorizacion obligatoria y estados seguros.

**Aplicacion de design-taste-frontend:** Material 3 como unico sistema;
variance 3, motion 2 y density 5; azul y formas suaves; controles con al menos
48 dp; radios y espacios centralizados; sin dashboard generico.

**Ciclo TDD:**

1. Probar navegacion EPS -> WaterScreen y Electrosur -> placeholder.
2. Probar boton deshabilitado sin autorizacion.
3. Probar labels, ocultar/mostrar clave, ayuda y aviso exacto.
4. Probar loading, errores tipados y limpieza visual de clave.
5. Probar pantalla 320x640, text scale 1.8 y semantica.
6. Implementar widgets y ruta.

**Comandos:**

```powershell
flutter test test/features/water/presentation/water_login_test.dart test/features/home
dart format lib/features/water/presentation lib/app test/features/water/presentation test/features/home
git diff --check
```

**Finalizacion:** formulario funcional y honesto; ninguna accion disponible
antes de autorizar el riesgo; sin overflow ni controles falsos.

## Tarea 8: resumen local, grafico e historiales

**Archivos:**

- Crear `lib/features/water/presentation/widgets/water_summary.dart`.
- Crear `lib/features/water/presentation/widgets/consumption_chart.dart`.
- Crear `lib/features/water/presentation/billing_history_screen.dart`.
- Crear `lib/features/water/presentation/billing_detail_screen.dart`.
- Crear `lib/features/water/presentation/payment_history_screen.dart`.
- Crear `lib/features/water/presentation/supply_details_screen.dart`.
- Modificar rutas y copy centralizado.
- Crear pruebas de widgets y navegacion bajo
  `test/features/water/presentation/`.

**Responsabilidad:** mostrar snapshot sin Internet, cifras diferenciadas,
grafico accesible, listas moviles y acciones confirmadas.

**Ciclo TDD:**

1. Probar resumen con importe, deuda y total diferenciados semanticamente.
2. Probar variacion solo con dos periodos comparables.
3. Probar grafico cronologico, sin meses inventados y alternativa textual.
4. Probar orden descendente de facturacion y pagos.
5. Probar detalle completo de recibo.
6. Probar campos de suministro disponibles y texto "No disponible en el
   portal" para campos ausentes.
7. Probar Actualizar pide password y reporta conteos.
8. Probar confirmaciones para cambiar/eliminar y borrado completo de Agua.
9. Implementar pantallas y `CustomPainter` sin paquete de graficos.

**Comandos:**

```powershell
flutter test test/features/water/presentation
dart format lib/features/water/presentation test/features/water/presentation
git diff --check
```

**Finalizacion:** todas las vistas funcionan con datos locales; grafico
accesible; navegacion nativa y borrado aislado verificados.

## Tarea 9: configuracion Android y pruebas de seguridad

**Archivos:**

- Modificar `android/app/src/main/AndroidManifest.xml`.
- Crear `android/app/src/main/res/xml/network_security_config.xml`.
- Crear `android/app/src/main/res/xml/backup_rules.xml`.
- Crear `android/app/src/main/res/xml/data_extraction_rules.xml`.
- Crear `android/app/proguard-rules.pro`.
- Modificar `android/app/build.gradle.kts` para ProGuard si corresponde.
- Crear `test/security/android_security_config_test.dart`.
- Crear `test/security/tracked_secret_scan_test.dart`.
- Crear `test/security/credential_lifecycle_test.dart`.

**Responsabilidad:** HTTP solo al dominio EPS, backups deshabilitados,
SQLCipher conservado por shrinker y busqueda de secretos sin imprimir valores.

**Ciclo TDD:**

1. Probar `usesCleartextTraffic=false` y Network Security con un solo dominio.
2. Probar ausencia de `includeSubdomains=true` y otros dominios cleartext.
3. Probar `allowBackup=false` y reglas de exclusion.
4. Probar reglas ProGuard SQLCipher.
5. Probar escaneo solo de archivos versionados; si encuentra candidatos,
   reporta rutas y lineas, nunca valores.
6. Implementar configuracion minima.

**Comandos:**

```powershell
flutter test test/security
rg -n "usesCleartextTraffic|cleartextTrafficPermitted|allowBackup|sqlcipher" android
git diff --check
```

**Finalizacion:** excepcion HTTP limitada y backups bloqueados; prueba de
secretos segura y sin falsos logs de valores.

## Tarea 10: documentacion, revision y verificacion integral

**Archivos:**

- Modificar `README.md`.
- Crear `AGENTS.md`.
- Crear `docs/architecture.md`.
- Crear `docs/data_dictionary.md`.
- Crear `docs/design_system.md`.
- Crear `docs/security.md`.
- Completar `docs/eps_tacna_connector.md`.
- Modificar codigo o pruebas solo si la revision encuentra un defecto real.

**Responsabilidad:** documentar datos, esquema, migracion 1, cifrado,
local-first, HTTP, cookies, cache, actualizacion, parsers y prueba manual.

**Revision:**

1. Ejecutar prueba completa y revisar arquitectura/capas.
2. Buscar secretos y APIs prohibidas.
3. Verificar que no hay password/cookies persistentes.
4. Verificar que las Views no importan `dart:io`, `html`, SQLCipher ni secure
   storage.
5. Ejecutar pre-flight de `design-taste-frontend` aplicable a movil:
   consistencia, contraste, estados, semantica, textos y controles.
6. Corregir con `systematic-debugging` cualquier fallo, sin debilitar pruebas.

**Comandos:**

```powershell
dart format .
flutter analyze
flutter test
git diff --check
git status --short
rg -n "Firebase|Supabase|analytics|telemetry|print\(|debugPrint" lib pubspec.yaml
rg -n "dart:io|package:html|sqflite|secure_storage" lib/features/water/presentation
```

**Finalizacion:** documentacion coincide con conducta verificada; analisis y
pruebas completos pasan; `.agents/` sigue sin seguimiento y sin cambios.

## Tarea 11: APK y prueba manual

**Archivos:** ninguno, salvo correccion de defectos demostrados.

**Responsabilidad:** validar plugin SQLCipher y Keystore en Android real,
instalar APK y ejecutar flujo real sin conservar secretos.

**Comandos:**

```powershell
flutter build apk --debug
Get-Item build\app\outputs\flutter-apk\app-debug.apk |
  Select-Object FullName,Length,LastWriteTime
```

**Prueba manual en telefono:**

1. Instalar APK debug.
2. Abrir Agua sin datos y verificar aviso/autorizacion.
3. Ingresar credenciales directamente en el telefono.
4. Sincronizar y comprobar resumen, todas las filas, pagos y detalles.
5. Cerrar la app, desconectar Internet y comprobar lectura local.
6. Volver a conectar, pulsar Actualizar y reingresar la contrasena.
7. Confirmar que no hay duplicados y que los conteos son coherentes.
8. Cambiar de suministro o eliminar Agua y comprobar borrado aislado.
9. Verificar que una base SQLCipher no abre sin su clave mediante la prueba de
   integracion prevista.

**Finalizacion:** APK existe, se instala y el usuario confirma el flujo. Solo
despues se puede considerar un commit final; no se hace merge a master.

## Criterios globales

- Portal real nunca usado por pruebas automaticas.
- Todas las filas de Facturacion y Pagos se procesan desde el HTML completo.
- Una sincronizacion parcial no modifica datos locales.
- Password y cookies no persisten.
- SQLCipher y secure storage funcionan en Android.
- HTTP solo permitido para el host EPS Tacna.
- Agua funciona offline despues de sincronizar.
- Interfaz Hogar claro accesible y sin funciones aparentes falsas.
- Formato, analisis, pruebas y APK debug verificados.
