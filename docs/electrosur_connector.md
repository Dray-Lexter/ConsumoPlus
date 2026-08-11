# Conector Electrosur

## Contrato observado y sanitizado

- Base: `http://www.electrosur.com.pe:81`.
- Login: `POST /Login`, formulario `application/x-www-form-urlencoded` con `GstrNumeroContrato` y `GstrClave`.
- Éxito: 302 hacia `/`, cookie `.ASPXAUTH` y `GET /` autenticado.
- Secciones HTML directas: `/EstadoCuenta`, `/Consumos`, `/Pagos` y `/Suministro`.

El flujo no usa Fetch/XHR. Los parsers localizan inputs readonly, etiquetas y encabezados normalizados. Aceptan cambios de espacios, saltos, mayúsculas, acentos y dos puntos.

## Normalización

- Periodos: `YYYYMM` validado y separado en año/mes.
- Consumo: kWh a Wh entero.
- Dinero: céntimos enteros. Decimales adicionales solo se aceptan cuando son ceros; una fracción significativa más allá de centésimos se rechaza.
- Fechas: valores válidos `dd/MM/yyyy` o ISO.
- Suministro: conexión, alimentador, potencia, tensión y medidor son opcionales.

## Sesión y errores

La cookie y la clave existen solo durante una sincronización. No hay una ruta de logout remoto verificada; cerrar el transporte destruye la sesión local en memoria.

La detección defensiva de credenciales rechazadas usa ausencia de `.ASPXAUTH`, retorno a `/Login` o reaparición de ambos campos del formulario. Después de autenticar, esas señales representan sesión expirada. Un fallo de parser conserva su error de sección y nunca se convierte en credenciales incorrectas.

## Verificación manual pendiente

- Confirmar el flujo completo en un teléfono Android con credenciales ingresadas directamente.
- Confirmar la señal específica que muestra el portal ante una clave incorrecta.
- Verificar en el futuro el endpoint oficial de logout y la URL oficial de recuperación de clave antes de habilitarlos.

Ninguna de estas verificaciones debe guardar HTML, cookies, claves ni datos personales.
