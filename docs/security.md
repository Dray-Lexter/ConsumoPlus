# Seguridad y privacidad

## Credenciales y sesiones

- Las claves viven solo en controladores de formulario y argumentos de la operación activa. No forman parte de estados, modelos, SQL ni almacenamiento seguro.
- Los controladores se limpian tras éxito, error, cancelación y `dispose`.
- Las cookies se guardan solo en memoria dentro de cada transporte y se destruyen en `close()` desde un bloque `finally`.
- Electrosur exige `.ASPXAUTH`; su valor nunca se expone, persiste ni registra.
- Se pueden recordar el usuario EPS Tacna y el contrato Electrosur, nunca sus claves.
- Excepciones y `toString()` contienen únicamente códigos y mensajes sanitizados.

Configuración resume estas condiciones sin prometer seguridad absoluta: informa que los datos locales están cifrados, que las claves no se almacenan, que las cookies son efímeras, que no existe una nube propia para el historial, que las conexiones dependen de cada proveedor, que EPS Tacna y Electrosur usan actualmente HTTP con autorización explícita y que cada módulo permite eliminar sus datos locales.

## Datos locales

`consumo_plus_water.db` conserva su nombre por compatibilidad, pero es la base compartida de la aplicación. Se abre en producción exclusivamente con `sqflite_sqlcipher` y una clave aleatoria de 32 bytes protegida por `flutter_secure_storage`.

No existe fallback a SQLite plano. Backups y transferencia Android están deshabilitados. Eliminar Agua o Electricidad borra solo sus tablas y su identificador recordado; la base y clave compartida permanecen para proteger el otro servicio.

El pronóstico lee exclusivamente la base cifrada y se calcula en memoria. No crea archivos, tablas o migraciones, no persiste sus resultados y no envía históricos ni estimaciones a servicios externos.

La integración `integration_test/sqlcipher_android_test.dart` verifica en Android que una clave ausente o incorrecta no puede leer la base:

```powershell
flutter test integration_test/sqlcipher_android_test.dart -d <device-id>
```

## Red

La configuración Android mantiene `usesCleartextTraffic="false"` y `base-config` en false. Solo permite HTTP a los hosts exactos:

- `oficinavirtual.epstacna.com.pe`
- `www.electrosur.com.pe`

No se incluyen subdominios. Cada transporte vuelve a validar esquema, host y puerto antes de enviar. La interfaz exige autorización explícita y recomienda evitar Wi-Fi público.

## Parsers, pruebas y registros

- Las pruebas automáticas nunca acceden a portales reales.
- Fixtures, nombres, direcciones, contratos, medidores y montos son ficticios.
- No hay interceptores de logging ni impresiones de cuerpos, cookies, cabeceras o credenciales.
- Controladores y resultados del pronóstico no incluyen consumos, importes, códigos de suministro o contratos en `toString()` ni logs.
- Credenciales rechazadas, sesión expirada, red, estructura por sección y almacenamiento son errores distintos.
- Un campo secundario ausente queda nulo sin invalidar datos obligatorios ya verificados.
- El escaneo de secretos reporta solo archivo y línea, nunca el valor sospechoso.

## Riesgo residual

ConsumoPlus no puede añadir cifrado en tránsito a portales HTTP. La advertencia y autorización reducen el uso inadvertido, pero una red hostil aún podría observar o alterar el tráfico. Solo los proveedores pueden resolver ese riesgo migrando a HTTPS.

## Firma y distribución Android

Las compilaciones Release se firman con una configuración dedicada cargada desde `android/key.properties`. El archivo, la keystore, `/dist/`, APK y AAB están excluidos de Git. Si falta la configuración completa, Gradle detiene una tarea Release y nunca recurre a la clave debug.

La keystore debe vivir fuera del repositorio y contar con una copia de seguridad cifrada. Consulta [preparación Release Android](release_android.md). Los iconos y el splash actuales siguen siendo provisionales y no constituyen recursos definitivos de marca.
