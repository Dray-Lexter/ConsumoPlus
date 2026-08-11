# ConsumoPlus — Electricidad / Electrosur

**Fecha:** 2026-08-11
**Estado:** especificación aprobada para implementación
**Rama:** `feature/electrosur-electricity`
**Base:** `6259fe79492c8b5fd74271bb84aabd4bc0729f3a`

## Alcance

La segunda etapa añade el módulo Electricidad para Electrosur, con lectura manual bajo demanda, persistencia local cifrada y consulta sin conexión después de una sincronización correcta. No incluye pagos, reclamos, descarga de recibos, sincronización en segundo plano, analítica, servicios cloud ni otros proveedores.

La interfaz conserva la dirección “Hogar claro”: Material 3, jerarquía doméstica, densidad media, movimiento discreto y una identidad ámbar/naranja para Electricidad. No replica el portal de Electrosur ni aparenta funciones no disponibles.

## Contrato remoto sanitizado

- Base exacta: `http://www.electrosur.com.pe:81`.
- Login: `POST /Login`, formulario `application/x-www-form-urlencoded`, campos `GstrNumeroContrato` y `GstrClave`.
- Éxito: respuesta 302 hacia `/`, cookie `.ASPXAUTH` y posterior `GET /` con HTML autenticado.
- Credenciales rechazadas: falta la cookie, retorno a `/Login` o reaparición del formulario con ambos campos. No se depende de una cadena de error no verificada.
- Sesión expirada: redirección a `/Login` o formulario de login dentro de una respuesta autenticada.
- Páginas: `GET /EstadoCuenta`, `/Consumos`, `/Pagos` y `/Suministro`.
- La cookie y la clave viven solo durante la sincronización y se descartan siempre al finalizar.
- No se inventa una ruta de logout ni una URL para “No tengo una clave”.

Los parsers comparan etiquetas y encabezados de forma semántica: normalizan espacios, saltos, mayúsculas, acentos y dos puntos; soportan `input readonly`, columnas reordenadas y campos secundarios opcionales. Un error estructural se informa por sección y nunca se convierte en credenciales incorrectas.

## Datos

Se implementan modelos inmutables para:

- `ElectricityAccount`
- `ElectricityAccountStatus`
- `ElectricityConsumptionRecord`
- `ElectricityPaymentRecord`
- `ElectricitySynchronizationMetadata`
- `ElectricitySnapshot`

El periodo remoto `YYYYMM` se divide en año y mes conservando también `sourcePeriodCode`. Los consumos se almacenan como Wh enteros. Los importes se almacenan en céntimos y solo admiten decimales adicionales cuando todos son cero.

Los campos secundarios de suministro (`connectionType`, `feederType`, `contractedPower`, `voltageLevel`, `meterNumber`) son opcionales. Su ausencia no invalida Estado de cuenta, Consumos ni Pagos.

## Arquitectura

El flujo será:

`ElectricityScreen → ElectricityViewModel → ElectrosurRepository → ElectrosurRemoteDataSource → ElectrosurHttpClient`

La rama local del repositorio será:

`ElectrosurRepository → ElectricityLocalDataSource → SQLCipher`

La aplicación compartirá una única instancia de infraestructura local cifrada entre Agua y Electricidad. La base física existente conservará su nombre para no perder instalaciones previas, pero su propiedad pasa a ser de la aplicación, no de un proveedor.

## Migración y aislamiento

- Esquema 1: tablas actuales de Agua.
- Esquema 2: conserva Agua y agrega las cinco tablas de Electricidad.
- Una instalación nueva crea ambos conjuntos.
- Una migración 1→2 crea únicamente Electricidad y verifica que los datos de Agua permanezcan intactos.
- Los registros usan claves únicas por proveedor, contrato y periodo/identidad remota, con upsert.
- Una sincronización fallida conserva el último snapshot correcto y registra solamente metadatos sanitizados cuando existe una cuenta local.
- “Eliminar datos de Electricidad” borra solo tablas de Electricidad y el contrato recordado.
- “Eliminar datos de Agua” deja de borrar el archivo completo o la clave compartida; borra exclusivamente filas de Agua y su usuario recordado.

## Interfaz

### Estado vacío / acceso

Explica que la conexión se realiza solo al pulsar sincronizar. Solicita número de contrato y clave; el contrato puede recordarse y la clave nunca. Incluye aviso por HTTP y un texto informativo “No tengo una clave” sin navegación externa.

### Resumen

Muestra último periodo, consumo en kWh, facturación del mes, deuda anterior, deuda total, saldo, vencimiento, variación respecto al periodo anterior y última sincronización. No muestra dirección ni medidor completos. Ofrece accesos a Estado de cuenta, Consumos, Pagos y Datos del suministro, además de actualización manual y eliminación local.

### Detalles

- Estado de cuenta: importes y fechas del periodo actual.
- Consumos: historial por periodo, tarifa, kWh y cargo mensual.
- Pagos: fecha, periodo, importe y centro.
- Suministro: contrato, titular, dirección, tarifa y campos secundarios disponibles.

Todos los estados —carga local, sincronización, contenido, error y eliminación— son explícitos y accesibles. Los mensajes posteriores al login distinguen sesión expirada, red, estructura de una sección y almacenamiento local.

## Seguridad

- `usesCleartextTraffic="false"` permanece globalmente.
- La configuración Android permite HTTP solo a `oficinavirtual.epstacna.com.pe` y `www.electrosur.com.pe`.
- No se persisten ni registran claves, cookies, HTML, cuerpos HTTP ni cabeceras sensibles.
- Los fixtures y pruebas usan exclusivamente identidades, direcciones, contratos y medidores ficticios.
- La misma SQLCipher y la misma clave protegida por almacenamiento seguro cubren ambos módulos.
- Las copias de seguridad Android continúan deshabilitadas.

## Criterios de aceptación

- Las 90 pruebas existentes siguen pasando.
- Hay cobertura dirigida para autenticación, cookie, sesión expirada, los cuatro parsers, campos opcionales, fechas, periodos, importes estrictos y kWh→Wh.
- La migración 1→2 conserva datos de Agua.
- Upsert evita duplicados y una falla no borra datos anteriores.
- La consulta local funciona sin red.
- Cada eliminación afecta solo a su servicio.
- Navegación, pantalla pequeña, texto ampliado y semántica están cubiertos.
- `dart format`, `flutter analyze`, `flutter test`, `git diff --check` y un APK debug final pasan.

## Limitaciones deliberadas

- La señal específica del portal para una clave incorrecta aún no fue observada; se aplica detección defensiva.
- El endpoint de logout remoto y la URL de recuperación de clave quedan pendientes de verificación futura.
- El contrato debe validarse manualmente en un teléfono con credenciales reales después de instalar el APK; ninguna prueba automatizada contacta el portal.
