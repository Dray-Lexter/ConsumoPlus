# Arquitectura de Agua

ConsumoPlus usa una arquitectura feature-first MVVM con dependencias por
constructor.

```text
WaterScreen -> WaterViewModel -> WaterRepository
                                  |-- WaterLocalStore -> SQLCipher
                                  |-- EpsTacnaRemoteSource
                                      -> parsers + HTTP + cookies en memoria
```

## Dominio

Contiene modelos inmutables, dinero en centimos, excepciones con mensajes
seguros y el contrato `WaterRepository`. No importa Flutter, HTTP, HTML ni SQL.

## Datos

`EpsTacnaRemoteDataSource` coordina login, cuenta, facturacion, pagos y logout.
Cada operacion crea un cliente nuevo; su contenedor de cookies se destruye en
`finally`. Los parsers ubican columnas por encabezado normalizado y rechazan
estructuras incompletas.

`WaterLocalDataSource` lee y actualiza las cuatro tablas en una transaccion.
`EpsTacnaRepository` solo persiste cuando la descarga completa fue validada.
En un fallo registra un codigo sanitizado cuando existe una cuenta local y
conserva el snapshot anterior.

## Aplicacion y presentacion

`WaterViewModel.initialize()` carga SQLCipher y el usuario recordado; nunca
llama al remoto. `synchronize()` recibe la clave como argumento y no la guarda
en estado ni campos. `WaterScreen` borra el controlador de clave tras cada
intento y al liberarse.

Las pantallas reciben modelos tipados. La navegacion usa `Navigator` y
`MaterialPageRoute`; ninguna View conoce endpoints, HTML o SQL.

## Incorporar otro proveedor

Un proveedor futuro implementara su fuente remota, parsers y configuracion,
reutilizando los modelos y presentacion que realmente compartan semantica. No
se crean selectores, carpetas vacias ni abstracciones especulativas en esta
etapa.
