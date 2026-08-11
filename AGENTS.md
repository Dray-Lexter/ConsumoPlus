# Reglas de trabajo de ConsumoPlus

## Límites del producto

- Tacna es la localidad inicial. EPS Tacna implementa Agua y Electrosur
  implementa Electricidad.
- Mantener modelos generales (`UtilityType`, `ProviderIdentity`,
  `WaterRepository`) y nombres específicos solo en adaptadores/configuración.
- No agregar backend, nube, scraping automático, analítica ni telemetría.
- Abrir un servicio nunca debe iniciar una consulta remota. Toda conexión es
  manual.

## Seguridad

- Nunca guardar, imprimir ni incluir en excepciones passwords, cookies,
  requests o responses del login.
- Usar solo fixtures sanitizados en pruebas. Nunca automatizar pruebas contra
  el portal real.
- La base de produccion se abre siempre con SQLCipher. La clave vive en secure
  storage; no existe fallback SQLite plano.
- Mantener las excepciones HTTP limitadas a los hosts exactos de EPS Tacna y
  Electrosur, y conservar los backups Android deshabilitados.
- No modificar ni versionar `.agents/` o `android/local.properties`.

## Flujo de cambios

- Implementar con pruebas primero y errores tipados.
- Mantener Views libres de `dart:io`, `html`, SQL y secure storage.
- Ejecutar formato, análisis, pruebas, `git diff --check` y escaneo de secretos.
- No crear el commit final ni integrar a `master` antes de instalar y probar el
  APK en un teléfono.
