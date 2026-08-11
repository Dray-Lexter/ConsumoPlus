# Arquitectura

ConsumoPlus usa arquitectura feature-first MVVM y dependencias por constructor.

```text
WaterScreen       -> WaterViewModel       -> WaterRepository
ElectricityScreen -> ElectricityViewModel -> ElectricityRepository
                                              |-- LocalDataSource -> SQLCipher
                                              |-- RemoteDataSource
                                                  -> parsers -> HTTP
```

Para Electrosur, el recorrido concreto es:

```text
ElectricityScreen -> ElectricityViewModel -> ElectrosurRepository
  -> ElectrosurRemoteDataSource -> ElectrosurHttpClient
  -> ElectricityLocalDataSource -> SQLCipher
```

## Dominio

Los modelos son inmutables. El dinero usa céntimos enteros y el consumo eléctrico usa Wh enteros. Las excepciones solo exponen códigos y mensajes sanitizados. El dominio no importa Flutter, HTTP, HTML ni SQL.

## Datos

Cada `RemoteDataSource` coordina una sincronización completa y crea una sesión nueva. Los parsers buscan etiquetas y encabezados normalizados y distinguen expiración de sesión de cambios estructurales.

Los repositorios escriben únicamente después de validar las secciones obligatorias. Los `LocalDataSource` hacen upsert dentro de una transacción; un fallo conserva el snapshot anterior. El bloque secundario Suministro de Electrosur es opcional y no descarta Estado de Cuenta, Consumos ni Pagos.

## Base compartida

`AppDependencies` comparte una sola instancia de `EncryptedAppDatabase`, almacenamiento seguro y clave SQLCipher. El archivo físico mantiene el nombre histórico `consumo_plus_water.db` para actualizar instalaciones existentes sin perder datos.

El esquema 2 conserva las cuatro tablas de Agua y agrega cinco de Electricidad. Cada módulo elimina solo sus filas y su identificador recordado; ningún repositorio borra la base o clave compartida.

## Aplicación y presentación

Los ViewModels cargan primero SQLCipher y el identificador recordado; no llaman la red durante `initialize()`. La clave llega como argumento a `synchronize()` y nunca forma parte del estado durable.

Las pantallas reciben modelos tipados y navegan con `Navigator` y `MaterialPageRoute`. Ninguna View conoce endpoints, HTML, SQL o almacenamiento seguro.
