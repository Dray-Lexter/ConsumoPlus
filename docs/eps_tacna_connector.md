# Conector EPS Tacna

Fecha de inspeccion: 2026-08-04
Portal: `http://oficinavirtual.epstacna.com.pe`
Estado: contrato autenticado inspeccionado con datos sensibles redactados

## Reglas de seguridad

- Nunca copiar credenciales, cookies, HTML completo ni valores de cuenta a
  codigo, fixtures, documentacion, capturas o logs.
- No registrar cuerpos de login, requests ni responses.
- Limitar todos los destinos HTTP al host exacto del portal.
- Mantener cookies y contrasena solo en memoria.
- Llamar al cierre oficial y destruir la sesion local en `finally`.
- Descartar cualquier cuerpo de error que pueda contener valores enviados.

## Login

```text
GET  /src/vista/v_login.php
POST /src/controlador/login.php
Content-Type: application/x-www-form-urlencoded

usu=<usuario>
pas=<clave>
```

El formulario no contiene campos ocultos. El documento declara UTF-8.

Senal de exito:

- destino `/src/controlador/main.php`;
- enlace de cierre `../controlador/salir.php`;
- menu con Historial de facturacion e Historial de pagos.

Senal de fallo: ausencia de las senales autenticadas anteriores.

El portal no proporciona un mensaje de error estable. Para ciertos usuarios
inexistentes puede devolver un error SQL que repite los valores enviados. El
conector no debe conservar, mostrar ni registrar ese contenido.

## Sesion y cookies

El GET publico del login no envio `Set-Cookie`. La herramienta de navegador no
expone encabezados del POST autenticado ni permite inspeccionar su almacen de
cookies, por lo que el nombre y atributos de la cookie no pudieron confirmarse
sin incumplir la politica de seguridad.

La implementacion usa `dart:io`:

- toma cookies tipadas de `HttpClientResponse.cookies`;
- conserva todas las cookies recibidas en un contenedor en memoria;
- las envia solo a `oficinavirtual.epstacna.com.pe`;
- no las serializa ni persiste;
- las elimina al cerrar sesion, terminar, cancelar o fallar.

Una sesion vencida se reconoce porque los endpoints autenticados devuelven de
nuevo un formulario con campos `usu` y `pas`, conservando incluso la URL del
endpoint solicitado y sin incluir la tabla esperada.

## Navegacion autenticada

La pagina principal es:

```text
/src/controlador/main.php
```

Los modulos se insertan en `#contenido` mediante jQuery `$.ajax` con metodo
POST.

### Facturacion

```text
POST /src/controlador/ctacte.php
```

No envia parametros. Devuelve HTML con tabla `#example1` y encabezados:

1. PERIODO
2. N° RECIBO
3. CONSUMO
4. LECT. PROM.
5. TOTAL MES
6. MES ATRAZ.
7. DEUDA
8. TOTAL

La tabla usa DataTables con `responsive: true`, `ordering: false` y
`autoWidth: false`. No declara `ajax` ni `serverSide`. La paginacion es solo
visual en el navegador: todas las filas vienen en una respuesta. En la cuenta
inspeccionada aparecieron dos paginas al mostrar diez filas; seleccionar 100
mostro todas las filas ya cargadas.

El conector debe parsear todas las filas del HTML original. No debe solicitar
paginas adicionales ni limitarse a las primeras diez.

### Pagos

```text
POST /src/controlador/historialpagos.php
```

No envia parametros. Devuelve HTML con tabla `#example1` y encabezados:

1. FECHA DE PAGO
2. CENTRO DE PAGO
3. ANO
4. MES
5. TIPO CP
6. N° COMPROBANTE
7. MONTO
8. DETALLE

Usa la misma configuracion DataTables del lado del cliente. En la cuenta
inspeccionada mostro una pagina visual. El parser debe consumir todas las filas
del HTML original.

### Cierre de sesion

```text
GET /src/controlador/salir.php
```

El cierre vuelve a `/src/vista/v_login.php`. Aunque la solicitud falle, la
aplicacion destruye inmediatamente las cookies locales.

## Datos del suministro

El bloque informativo situado sobre la tabla de `ctacte.php` puede exponer los
siete datos del suministro: codigo de cliente, titular, direccion, estado o
servicio, tarifa, medidor y tipo de conexion. El conector los lee mediante
etiquetas normalizadas y alias conocidos. Si el bloque no repite el codigo o el
titular, conserva la identidad ya validada durante el login.

Direccion, estado, tarifa, medidor y tipo de conexion son campos secundarios y
opcionales. La ausencia de uno de ellos produce un valor nulo y no invalida la
facturacion, los pagos ni la sincronizacion completa. El recibo virtual no se
utiliza: `POST recibo.php` y luego `POST ../vista/mostrar_pdf.php` solo abren un
visor y permanecen fuera del alcance del conector.

Una vez aceptado el login, una estructura incompatible de Facturacion o Pagos
se informa como error de esa etapa de sincronizacion. No se transforma en un
error de credenciales.

## Mantenimiento de parsers

Si el portal cambia:

1. Repetir la inspeccion con una cuenta introducida manualmente.
2. No guardar el HTML real completo.
3. Crear un fragmento minimo sanitizado con nombres, codigos, recibos, montos
   y fechas sustituidos.
4. Actualizar primero pruebas de contrato y encabezados.
5. Mantener busqueda por encabezado normalizado, no solo por indice.
6. Tratar una pagina completamente ajena como
   `UnexpectedPortalStructureException`; despues de un login aceptado, mapear
   estructuras incompatibles a `BillingHistoryStructureException` o
   `PaymentHistoryStructureException`, segun la etapa.
7. No hacer obligatorios los campos secundarios del suministro ni abortar por
   su ausencia.
8. Tratar la reaparicion del formulario de login como
   `SessionExpiredException`.
