# ConsumoPlus: etapa 2, Agua con EPS Tacna

Fecha: 2026-08-04
Estado: aprobada por el usuario; inspeccion tecnica autenticada completada
Rama: `feature/eps-tacna-water`
Base: `113f6448a10a6cc460d13fb8aff1a71846b2d327`

## 1. Objetivo

La segunda etapa convierte la opcion Agua en un modulo local-first para EPS
Tacna. El usuario podra autorizar una consulta directa desde su telefono,
autenticarse contra el portal oficial, descargar su cuenta, facturacion y
pagos, conservar una copia local cifrada y consultar esa copia sin Internet.

No se implementa Electrosur, un backend, sincronizacion automatica, tareas en
segundo plano, analitica ni almacenamiento en la nube.

## 2. Principios de producto

- Flujo de datos: usuario -> ConsumoPlus -> EPS Tacna -> ConsumoPlus -> base
  local cifrada.
- Apertura local-first: Agua lee y presenta primero la base local.
- La red se usa solo por una accion explicita de ingreso o actualizacion.
- La contrasena vive solo durante la sincronizacion y nunca se persiste.
- El usuario de EPS puede recordarse localmente.
- Las cookies de sesion viven solo en memoria y se destruyen al terminar.
- Una sincronizacion fallida nunca elimina datos locales validos.
- El portal usa HTTP. La interfaz explica el riesgo y exige autorizacion.
- Android permite HTTP solamente a `oficinavirtual.epstacna.com.pe`.
- Los errores visibles son comprensibles y no exponen HTML, credenciales,
  cookies, SQL ni detalles internos del portal.

## 3. Alcance funcional

### 3.1 Sin datos locales

`WaterScreen` presenta:

- Agua y EPS Tacna.
- Explicacion breve del uso local-first.
- Campo Usuario.
- Campo Clave con accion para mostrar u ocultar.
- Aviso: "El portal de EPS Tacna utiliza actualmente una conexion no
  cifrada. Evita ingresar desde redes Wi-Fi publicas. ConsumoPlus no almacena
  tu contrasena."
- Casilla real: "Comprendo el riesgo y autorizo esta consulta."
- Boton "Ingresar y obtener mis datos", deshabilitado hasta aceptar.
- Estado de carga y error contextual.
- Informacion "¿Donde encuentro mis datos?" con el texto "El usuario y la
  clave aparecen en tu recibo de EPS Tacna."

Al terminar cualquier intento se limpia el controlador de contrasena.

### 3.2 Con datos locales

Los datos locales se muestran inmediatamente, aunque no exista Internet:

- ultimo periodo;
- ultimo consumo en m3;
- importe del mes;
- deuda registrada;
- total mostrado por EPS;
- variacion respecto al periodo anterior;
- ultima actualizacion;
- grafico de los ultimos 6 o 12 periodos disponibles;
- accesos a Facturacion, Pagos y Detalles del suministro;
- boton Actualizar.

Actualizar abre una solicitud de contrasena, muestra el usuario recordado,
permite cambiarlo y comunica al finalizar cuantas filas fueron insertadas o
actualizadas.

### 3.3 Facturacion

Lista vertical ordenada del periodo mas reciente al mas antiguo. Cada fila
muestra mes y ano, consumo, recibo, importe mensual, deuda y total. El detalle
muestra todos los campos del modelo sin reproducir la tabla horizontal del
portal.

### 3.4 Pagos

Lista vertical ordenada por fecha descendente. Cada fila muestra fecha,
periodo, monto, centro de pago, comprobante y detalle.

### 3.5 Detalles del suministro

Muestra codigo de cliente parcialmente oculto, titular, direccion, estado,
tarifa, medidor parcialmente oculto y tipo de conexion. Ofrece dos acciones
confirmadas:

- Cambiar de suministro: elimina solamente el modulo Agua y vuelve al ingreso.
- Eliminar datos de Agua: elimina cuenta, facturacion, pagos, metadatos,
  usuario recordado y, si no protege otro modulo, la clave de la base.

La eliminacion se limita por `providerId` y no afectara Electricidad.

## 4. Arquitectura

Se mantiene feature-first con MVVM y dependencias por constructor:

```text
WaterScreen
  -> WaterViewModel
    -> EpsTacnaRepository
      -> EpsTacnaRemoteDataSource
        -> EpsTacnaAuthenticator
        -> EpsTacnaProfileDataSource
        -> EpsTacnaBillingDataSource
        -> EpsTacnaPaymentsDataSource
        -> EpsTacnaHttpClient
        -> InMemoryCookieJar
      -> WaterLocalDataSource
        -> EncryptedWaterDatabase
          -> DatabaseKeyStore
```

Limites:

- Presentacion administra estados y eventos, no HTTP, cookies, HTML ni SQL.
- El repositorio coordina lectura local, sincronizacion y transacciones.
- El cliente HTTP aplica dominio permitido, timeout, redirecciones y cierre.
- La sesion administra cookies solo en memoria.
- Cada parser valida autenticacion, encabezados y estructura.
- La persistencia expone modelos tipados y transacciones, no mapas a la UI.
- El reloj y las dependencias de red, clave y almacenamiento son reemplazables
  en pruebas.

La implementacion no concentrara estas responsabilidades en una unica clase
`EpsTacnaService`.

## 5. Modelos

Todos los modelos son inmutables. El dinero se representa en centimos enteros.

### 5.1 WaterAccount

- `providerId`
- `customerCode`
- `ownerName`
- `serviceAddress` opcional; EPS Tacna lo obtiene del bloque de facturacion
- `serviceStatus` opcional; EPS Tacna lo obtiene del bloque de facturacion
- `tariffName` opcional; EPS Tacna lo obtiene del bloque de facturacion
- `meterNumber` opcional; EPS Tacna lo obtiene del bloque de facturacion
- `connectionType` opcional; EPS Tacna lo obtiene del bloque de facturacion
- `synchronizedAt`

### 5.2 BillingRecord

- `providerId`
- `customerCode`
- `billingYear`
- `billingMonth`
- `sourcePeriodLabel`
- `receiptNumber`
- `consumptionCubicMeters`
- `averageReading`
- `monthlyChargeCents`
- `overdueMonths`
- `outstandingDebtCents`
- `totalAmountCents`
- `synchronizedAt`

Clave unica: `providerId + customerCode + receiptNumber`.

### 5.3 PaymentRecord

- `providerId`
- `customerCode`
- `paymentDate`
- `paymentCenter`
- `paymentYear`
- `paymentMonth`
- `documentType`
- `receiptNumber`
- `amountCents`
- `detail`
- `synchronizedAt`

Clave unica: `providerId + customerCode + receiptNumber + paymentDate +
amountCents`.

### 5.4 SynchronizationMetadata

- `providerId`
- `customerCode`
- `lastAttemptAt`
- `lastSuccessfulSyncAt`
- `status`
- `sanitizedErrorCode`
- `insertedBillingRecords`
- `updatedBillingRecords`
- `insertedPaymentRecords`
- `updatedPaymentRecords`

## 6. Persistencia y cifrado

La base usa SQLCipher real mediante `sqflite_sqlcipher`; no se aceptara una
degradacion silenciosa a SQLite sin cifrar.

Propuesta de esquema version 1:

- `water_accounts`
- `billing_records`
- `payment_records`
- `synchronization_metadata`

Las escrituras de una sincronizacion se ejecutan en una sola transaccion. Se
hace upsert sobre las claves unicas. Campos mutables como deuda, total y meses
atrasados se actualizan si el portal cambia. La transaccion solo reemplaza el
estado local cuando todas las descargas y parsers obligatorios terminan.

La clave SQLCipher:

1. Se crea con bytes aleatorios de `Random.secure()`.
2. Se codifica para su almacenamiento, sin registrarla.
3. Se guarda con `flutter_secure_storage` y Android Keystore.
4. Nunca se incluye en SQL, fixtures, documentacion, excepciones ni logs.
5. Se elimina cuando Agua ya no tiene datos y no protege otro modulo.

Android deshabilita copias de seguridad de la aplicacion. La base, las
preferencias seguras y cualquier archivo sensible quedan fuera de Auto Backup
y device transfer.

## 7. Evaluacion de dependencias

Evaluacion realizada el 2026-08-04 para Flutter 3.44.8, Dart 3.12.2, minSdk
24 y targetSdk 36:

- `sqflite_sqlcipher 3.4.1`: SQLCipher 4.x; declara Dart >=3.9 y Flutter
  >=3.35. Su implementacion Android declara minSdk 21, Java 17 y
  `sqlcipher-android 4.10.0`. Es compatible con el proyecto.
- `flutter_secure_storage 10.3.1`: almacenamiento seguro con RSA-OAEP y
  AES-GCM en Android; minSdk 23. Es compatible con minSdk 24.
- `http 1.6.0`: evaluado, pero no se agregara. `dart:io HttpClient` ya ofrece
  cookies tipadas, redirecciones controlables, cierre y cancelacion sin sumar
  una dependencia.
- `html 0.15.6`: parser HTML mantenido por `tools.dart.dev`, usado solamente
  para transformar respuestas en modelos tipados.

No se agrega paquete de graficos. Un `CustomPainter` pequeno, semantica y una
alternativa textual cubren el grafico requerido sin ampliar dependencias.

La compatibilidad final exige resolver dependencias, compilar el APK y abrir
una base cifrada en Android. Si esa verificacion falla, el desarrollo se
detendra antes de sustituir SQLCipher.

## 8. Contrato del portal

### 8.1 Hallazgos publicos confirmados

Inspeccion tecnica del 2026-08-04:

- URL de acceso:
  `http://oficinavirtual.epstacna.com.pe/src/vista/v_login.php`.
- Titulo: `EPS Tacna | Oficina virtual`.
- Codificacion declarada por el documento: UTF-8.
- Metodo: `POST`.
- Destino:
  `http://oficinavirtual.epstacna.com.pe/src/controlador/login.php`.
- Tipo de cuerpo: `application/x-www-form-urlencoded`.
- Usuario: campo `usu`, id `usu`.
- Clave: campo `pas`, id `pas`, tipo `password`.
- No se observaron campos ocultos en el formulario publico.

No se ha enviado ninguna credencial ni se ha guardado HTML de una cuenta.

### 8.2 Hallazgos autenticados

- Un login correcto termina en `/src/controlador/main.php` y presenta el
  enlace `../controlador/salir.php` y el menu autenticado.
- Un login incorrecto no ofrece una senal de producto estable. El portal
  puede responder desde `login.php` con un error SQL que repite los valores
  enviados. La aplicacion nunca muestra ni registra ese cuerpo: cualquier
  respuesta sin la senal autenticada se clasifica como credenciales invalidas.
- Facturacion se solicita con `POST ctacte.php`, sin parametros de cuerpo.
- Pagos se solicita con `POST historialpagos.php`, sin parametros de cuerpo.
- Ambas respuestas incluyen una tabla `#example1` y se paginan en el cliente
  con DataTables. No existe AJAX por pagina ni `serverSide`.
- Facturacion mostro dos paginas visuales al limitar a diez filas, pero al
  elegir 100 se mostraron todas las filas ya cargadas. El parser debe leer el
  HTML original completo, no reproducir la paginacion visual.
- Pagos mostro una pagina visual en la cuenta inspeccionada y usa el mismo
  mecanismo cliente.
- Los encabezados de facturacion son PERIODO, N° RECIBO, CONSUMO, LECT.
  PROM., TOTAL MES, MES ATRAZ., DEUDA y TOTAL.
- Los encabezados de pagos son FECHA DE PAGO, CENTRO DE PAGO, ANO, MES,
  TIPO CP, N° COMPROBANTE, MONTO y DETALLE.
- Sin sesion, `ctacte.php` responde en la misma URL con el formulario de login
  `usu`/`pas` y sin tabla. Esa es la senal de sesion vencida.
- El cierre oficial usa `GET ../controlador/salir.php` y vuelve al login.
- El documento autenticado se interpreto como UTF-8.
- El HTML expone el titular en la barra lateral y el codigo corresponde al
  usuario introducido. La respuesta de facturacion tambien incluye direccion,
  estado, tarifa, medidor y tipo de conexion en su bloque informativo previo a
  la tabla.
- El recibo virtual usa `POST recibo.php` y luego `POST
  ../vista/mostrar_pdf.php` dentro de un visor. No proporciona esos datos como
  HTML y no se agregara parsing de PDF fuera del alcance acordado.

El navegador no expone encabezados del POST autenticado ni permite leer su
almacen de cookies. Un GET publico al login no envio `Set-Cookie`. Por tanto,
no se documenta un nombre inventado: `HttpClientResponse.cookies` capturara
cualquier cookie real, se reenviara solo al host permitido y se eliminara de
memoria al cerrar la sesion.

## 9. Parsing y errores

Los parsers:

- rechazan una respuesta que corresponda al login o a sesion vencida;
- encuentran columnas por encabezado normalizado, no solo por indice;
- toleran espacios, saltos, mayusculas y minusculas;
- convierten meses en espanol a 1-12;
- convierten fechas a `DateTime` local sin hora inventada;
- convierten importes con `S/` y separadores a centimos;
- detectan tabla ausente, encabezado faltante y estructura inesperada;
- producen modelos tipados.

Errores de dominio:

- `InvalidCredentialsException`
- `SessionExpiredException`
- `PortalUnavailableException`
- `UnexpectedPortalStructureException`
- `NetworkTimeoutException`
- `IncompleteSynchronizationException`

Cada error tiene un codigo sanitizado para metadatos y un mensaje de producto
sin contenido sensible.

## 10. Paginacion y sincronizacion

Las dos tablas incluyen todas sus filas en el HTML y DataTables pagina solo en
el cliente. Cada endpoint se solicita una vez y el parser procesa todas las
filas del documento original, sin parametros de pagina.

La sincronizacion se considera completa solo si cuenta, todas las paginas de
facturacion y todas las paginas de pagos fueron validadas. Una respuesta
parcial produce `IncompleteSynchronizationException` y conserva la base.

## 11. Seguridad Android y red

- Permiso `INTERNET` explicito.
- `android:usesCleartextTraffic="false"` como valor general.
- Network Security Config con `cleartextTrafficPermitted="true"` solamente
  para `oficinavirtual.epstacna.com.pe`, sin incluir subdominios.
- Sin validaciones TLS deshabilitadas, certificados ignorados ni dominios
  alternativos permitidos.
- `android:allowBackup="false"` y reglas de extraccion/backup restrictivas.
- Sin interceptores de logging ni impresiones de request/response.
- Timeout y cancelacion por cierre del cliente o token cooperativo.
- Cookies manuales en memoria y destruidas incluso ante error.
- El cliente rechaza destinos cuyo host no sea el proveedor configurado.

## 12. Direccion visual

Design Read: aplicacion movil nativa de servicios basicos para hogares de
Tacna, con lenguaje domestico y de confianza, apoyada en Material 3 y la
identidad "Hogar claro".

Diales aplicados de `design-taste-frontend`:

- `DESIGN_VARIANCE: 3`
- `MOTION_INTENSITY: 2`
- `VISUAL_DENSITY: 5`

La skill declara que el producto movil nativo queda fuera de su alcance
principal. Por eso se conservan Material 3 y las guias nativas. Se aplican
solo sus principios compatibles: jerarquia clara, un sistema visual,
consistencia de radios y color, contraste, estados loading/empty/error,
accesibilidad, texto funcional y ausencia de apariencia generica de dashboard.

Agua usa azul y formas suaves. Importe mensual, deuda y total tienen jerarquia
visual distinta sin usar color como unico indicador. No se mostraran estados
falsos ni controles sin funcion.

## 13. Grafico accesible

El grafico usa solo los 6 o 12 periodos locales existentes, ordenados
cronologicamente. No completa meses ausentes. El eje expresa m3 y nunca mezcla
montos. Se acompana de una lista o resumen textual accesible con periodo y
consumo. El pintado no sustituye la semantica.

## 14. Estrategia de pruebas

Las pruebas automaticas nunca llaman al portal real. Se usaran clientes falsos
y fixtures HTML minimos, sanitizados y sin datos de cuenta reales.

Cobertura obligatoria:

- login correcto con cliente falso;
- credenciales incorrectas;
- sesion vencida;
- portal no disponible y timeout;
- parsers de cuenta, facturacion y pagos;
- meses, fechas e importes en centimos;
- estructura inesperada y encabezados faltantes;
- todas las paginas de facturacion y pagos;
- upsert sin duplicados y actualizacion de deuda/total;
- persistencia tras reabrir repositorio/base;
- conservacion local ante fallo o sincronizacion incompleta;
- lectura local sin Internet;
- nueva solicitud de contrasena al actualizar;
- contrasena limpiada tras exito y error;
- cookies destruidas al terminar;
- eliminacion completa y aislada de Agua;
- navegacion a facturacion, pagos y detalles;
- texto aumentado, pantalla pequena y semantica;
- ausencia de secretos en errores y archivos versionados;
- configuracion Android de HTTP limitada al dominio EPS;
- exclusion de backups.

La persistencia real cifrada se verificara ademas en una prueba de integracion
Android o durante la prueba manual: crear base, escribir, cerrar, reabrir con
clave correcta y comprobar que una apertura sin clave o con clave incorrecta
no puede leerla.

## 15. Criterios de finalizacion

- Inspeccion autenticada completa y documentada con valores sensibles
  redactados.
- Dependencias resueltas y SQLCipher probado en Android.
- Arquitectura y modelos descritos implementados sin mezclar capas.
- Todas las paginas de facturacion y pagos se obtienen o la sincronizacion
  falla de forma segura.
- Agua funciona con datos locales sin red.
- Contrasena y cookies nunca persisten.
- Excepcion HTTP y backups verificados.
- Interfaz completa, accesible y coherente con Hogar claro.
- `dart format .`, `flutter analyze`, `flutter test` y build APK debug pasan.
- APK instalado y probado manualmente con credenciales ingresadas por el
  usuario.
- No se hace merge a master ni commit final antes de la prueba en telefono.

## 16. Fuera de alcance

- Electrosur funcional.
- Selector de ciudad o proveedor.
- Backend, nube, analitica, telemetria, publicidad o reporte externo.
- Guardado de contrasena o cookies.
- Sincronizacion automatica o periodica.
- Reintentos repetitivos.
- Pago de recibos desde la aplicacion.
- Formularios o scraping de proveedores distintos de EPS Tacna.
