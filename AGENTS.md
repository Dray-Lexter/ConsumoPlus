# Reglas de trabajo de ConsumoPlus

## Limites del producto

- Tacna es la localidad inicial. EPS Tacna es la implementacion de Agua y
  Electrosur sigue demostrativa.
- Mantener modelos generales (`UtilityType`, `ProviderIdentity`,
  `WaterRepository`) y nombres especificos solo en adaptadores/configuracion.
- No agregar backend, nube, scraping automatico, analitica ni telemetria.
- Abrir Agua nunca debe iniciar una consulta remota. Toda conexion es manual.

## Seguridad

- Nunca guardar, imprimir ni incluir en excepciones passwords, cookies,
  requests o responses del login.
- Usar solo fixtures sanitizados en pruebas. Nunca automatizar pruebas contra
  el portal real.
- La base de produccion se abre siempre con SQLCipher. La clave vive en secure
  storage; no existe fallback SQLite plano.
- Mantener la excepcion HTTP limitada al host exacto de EPS Tacna y conservar
  backups Android deshabilitados.
- No modificar ni versionar `.agents/` o `android/local.properties`.

## Flujo de cambios

- Implementar con pruebas primero y errores tipados.
- Mantener Views libres de `dart:io`, `html`, SQL y secure storage.
- Ejecutar formato, analisis, pruebas, `git diff --check` y escaneo de secretos.
- No crear el commit final ni integrar a `master` antes de instalar y probar el
  APK en un telefono.
