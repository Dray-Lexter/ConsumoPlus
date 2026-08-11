# ConsumoPlus 0.2.0 Beta: diseño de hardening y preparación Release

## Objetivo

Preparar el estado funcional ya validado de ConsumoPlus para una beta cerrada
Android, sin ampliar la lógica de negocio ni alterar scraping, parsers,
predicción, SQLCipher o persistencia. El resultado debe informar con precisión
los límites de privacidad y de las estimaciones, usar versión `0.2.0+2` y quedar
preparado para artefactos Release firmados con una clave privada del propietario.

## Alcance aprobado

- Hardening localizado de textos, configuración Android y distribución.
- Información de privacidad visible en Configuración.
- Descargo visible para los rangos predictivos.
- Versión técnica `0.2.0+2` y texto visible `Versión 0.2.0 Beta`.
- Limpieza exclusiva de textos vigentes que aún describan la aplicación como
  demostrativa, prototipo, pendiente o no implementada.
- Firma Release mediante `android/key.properties` local e ignorado.
- Conservación de R8/minificación actual, con verificación posterior.
- Preparación de APK universal, APK separados por ABI y AAB.
- Documentación del icono y splash provisionales, sin crear marca nueva.

Quedan fuera de alcance nuevas funciones, cambios en conectores, cambios de
esquema, almacenamiento de contraseñas, backend, nube, telemetría, publicación,
push, tag y commit antes de la prueba manual del Release.

## Experiencia visible

### Configuración

Configuración seguirá siendo una pantalla informativa, sin interruptores ni
controles que aparenten funciones inexistentes. Presentará información clara y
no absoluta:

- los datos locales se guardan cifrados en el dispositivo;
- las contraseñas de EPS Tacna y Electrosur no se almacenan;
- las cookies de sesión existen solo durante la sincronización;
- ConsumoPlus no usa una nube propia para el historial;
- cada conexión hereda las condiciones de seguridad del proveedor;
- ambas integraciones actuales usan HTTP y requieren autorización explícita;
- el usuario puede eliminar sus datos locales desde cada módulo.

La pantalla mostrará `Versión 0.2.0 Beta`. Se retirará la fila de Apariencia que
solo anunciaba una versión futura, porque no aporta una acción ni información
necesaria para esta beta.

### Estimaciones

La sección de pronóstico mostrará, una sola vez y de forma legible, el texto:

> Las estimaciones son orientativas y no garantizan el consumo ni el importe futuro.

El mismo significado se incluirá en la descripción semántica para tecnologías
de asistencia. No se cambiarán cálculos, modelos, rangos ni reglas temporales.

## Configuración Android

- `applicationId`: `pe.consumoplus.consumo_plus`.
- SDK efectivos del Flutter actual: mínimo 24, objetivo 36, compilación 36.
- Único permiso de aplicación: Internet.
- Cleartext global deshabilitado; excepciones solo para
  `oficinavirtual.epstacna.com.pe` y `www.electrosur.com.pe`.
- Backups y transferencia de datos deshabilitados/excluidos.
- R8 y `proguard-android-optimize.txt` se mantienen sin cambios agresivos.

La configuración Release cargará `android/key.properties`, creará una
`signingConfig` dedicada y nunca recurrirá a la clave debug. Si se solicita una
tarea Release sin configuración completa, Gradle debe fallar con un mensaje
seguro que no revele contraseñas ni rutas sensibles innecesarias.

`key.properties`, `*.jks`, `*.keystore`, `*.aab` y `/dist/` permanecerán fuera
de Git. La keystore se guardará fuera del repositorio y su creación será manual,
interactiva y posterior a esta preparación.

## Recursos visuales provisionales

El icono y el splash actuales son los recursos predeterminados de Flutter. No
se reemplazarán en esta etapa. Para la sustitución futura se requerirá un recurso
oficial de marca, preferiblemente un PNG maestro cuadrado de 1024 x 1024 px y,
si se desea icono adaptativo, capas de primer plano y fondo definidas.

## Validación y punto de detención

Antes de solicitar la clave se ejecutarán pruebas localizadas, formato, análisis,
suite completa y `git diff --check`. Se repetirá un escaneo redactado de secretos,
datos personales y artefactos locales.

Cuando la preparación pase estas verificaciones y la única condición pendiente
para compilar Release sea la keystore, el trabajo se detendrá. El propietario
recibirá el comando interactivo, la ruta y alias recomendados, la plantilla de
`android/key.properties`, la comprobación de ignorados y el procedimiento de
respaldo. No se generarán artefactos ni commits hasta que la firma se configure y
el APK Release sea probado manualmente.
