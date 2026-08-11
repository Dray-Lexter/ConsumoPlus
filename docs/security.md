# Seguridad y privacidad

## Credenciales y sesion

- La clave se mantiene solo en el controlador del formulario y en la pila de la
  operacion activa; nunca forma parte de `WaterState`, modelos, SQL o secure
  storage. El controlador se limpia tras exito, error, cancelacion y dispose.
- Las cookies se manejan como objetos `Cookie` en `InMemoryCookieJar`. No se
  serializan y se eliminan al cerrar el cliente.
- Excepciones y `toString()` exponen solo codigos y mensajes sanitizados.
- El usuario puede recordarse; se guarda separado de la base mediante
  `flutter_secure_storage`.

## Datos locales

`consumo_plus_water.db` se abre en produccion exclusivamente mediante
`sqflite_sqlcipher` y un password aleatorio de 32 bytes. La clave se genera con
`Random.secure` y se guarda con `flutter_secure_storage`, respaldado por el
almacenamiento seguro de Android. El borrado de Agua elimina filas, archivo de
base, usuario recordado y clave.

No existe fallback a SQLite plano. Los backups y transferencia Android estan
deshabilitados y las reglas excluyen archivos, bases y preferencias.

La prueba `integration_test/sqlcipher_android_test.dart` crea una base cifrada
en un dispositivo Android y verifica que una clave ausente o incorrecta no
pueda leerla. Se ejecuta con:

```powershell
flutter test integration_test/sqlcipher_android_test.dart -d <device-id>
```

## Red

La configuracion base de Android bloquea cleartext. Una unica regla permite
HTTP al dominio exacto `oficinavirtual.epstacna.com.pe`, sin subdominios. El
transporte vuelve a validar esquema, host y puerto en cada solicitud y
redireccion. La UI exige una autorizacion marcada antes de habilitar el boton.

## Pruebas y registros

- Las pruebas automaticas nunca acceden al portal real.
- Fixtures, nombres, codigos, recibos y montos son ficticios y sanitizados.
- No existen interceptores de logging ni impresiones de cuerpos HTTP.
- El escaneo de secretos revisa fuentes candidatas y, ante un hallazgo, informa
  solo ruta y linea.
- Las credenciales incorrectas se distinguen de fallos de Facturacion, Pagos o
  almacenamiento ocurridos despues de aceptar el login. Todos exponen solo un
  codigo y un mensaje seguros.
- Un campo secundario ausente en el bloque informativo de Facturacion queda
  nulo y no descarta los demas datos ya validados.

## Amenazas fuera de alcance

ConsumoPlus no puede aportar cifrado en transito que el servidor HTTP de EPS
Tacna no ofrece. La advertencia y autorizacion reducen el riesgo de uso
inadvertido, pero una red hostil aun podria observar o alterar trafico. El
proveedor debe migrar a HTTPS para resolver ese riesgo de raiz.
