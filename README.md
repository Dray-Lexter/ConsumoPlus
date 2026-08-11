# ConsumoPlus

Aplicacion Flutter para consultar servicios domesticos en Tacna. La version
`0.1.0` implementa Agua con EPS Tacna y conserva Electricidad con Electrosur
como espacio demostrativo.

## Agua en esta etapa

- El usuario inicia la consulta manualmente y autoriza de forma explicita la
  conexion HTTP del portal de EPS Tacna.
- La clave y las cookies solo existen en memoria durante la consulta.
- El nombre de usuario puede recordarse mediante el almacenamiento seguro de
  Android.
- Cuenta, recibos, pagos y metadatos se guardan en una base SQLCipher local.
- Al volver a Agua, la app lee primero la copia local y no usa la red.
- Actualizar siempre solicita nuevamente la clave.
- Los historiales, el grafico y los detalles funcionan sin Internet despues de
  una sincronizacion correcta.
- Una descarga parcial o fallida conserva los datos validos anteriores.

Los datos del suministro se extraen del bloque informativo de Facturacion. Los
campos secundarios, como direccion, estado, tarifa, medidor y tipo de conexion,
son opcionales: si alguno no aparece, la app muestra
`No disponible en el portal` sin invalidar el resto de la sincronizacion ni
inventar valores. Un error posterior a un login aceptado se informa como fallo
de sincronizacion, no como credenciales incorrectas.

## Seguridad importante

EPS Tacna sirve su oficina virtual mediante HTTP. Android bloquea HTTP por
defecto en la app y permite una excepcion solo para
`oficinavirtual.epstacna.com.pe`. El formulario explica el riesgo antes de
habilitar la conexion. ConsumoPlus no incluye backend, nube, analitica ni
telemetria.

Consulta [docs/security.md](docs/security.md) y
[docs/eps_tacna_connector.md](docs/eps_tacna_connector.md) para los detalles.

## Ejecutar y verificar

Requiere Flutter 3.44.8/Dart 3.12.2, Java 17 y Android SDK configurado.

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`.

## Estructura

```text
lib/
  app/                    rutas, tema y configuracion de producto
  core/                   identidad de proveedores e inicio reemplazable
  features/water/
    application/          WaterViewModel, estados y composicion
    domain/               modelos, errores y contrato del repositorio
    data/
      remote/             HTTP, cookies en memoria y fuente EPS Tacna
      parsers/            HTML a modelos tipados
      local/              SQLCipher, esquema y almacenamiento seguro
      repositories/       sincronizacion atomica local-first
    presentation/         pantallas Material 3 y widgets
  features/home/          entrada a Agua y Electricidad
  features/provider/      placeholder reutilizable para Electrosur
test/                     unitarias, widgets, seguridad y fixtures sanitizados
```

Documentos adicionales:

- [docs/architecture.md](docs/architecture.md)
- [docs/data_dictionary.md](docs/data_dictionary.md)
- [docs/design_system.md](docs/design_system.md)
- [docs/security.md](docs/security.md)
- [docs/eps_tacna_connector.md](docs/eps_tacna_connector.md)

No se deben usar credenciales reales en pruebas, fixtures, capturas, commits o
documentacion. La prueba manual del portal se realiza unicamente en un telefono
o sesion controlada, ingresando las credenciales directamente.
