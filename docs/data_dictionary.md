# Diccionario de datos de Agua

Todos los registros incluyen `provider_id`, `customer_code` y fecha de
sincronizacion. Los importes se almacenan como centimos enteros.

## `water_accounts`

| Campo | Tipo | Origen |
| --- | --- | --- |
| `provider_id` | texto | configuracion (`eps-tacna`) |
| `customer_code` | texto | bloque de facturacion; respaldo: usuario validado |
| `owner_name` | texto | bloque de facturacion; respaldo: sesion autenticada |
| `service_address` | texto nullable | bloque informativo de facturacion |
| `service_status` | texto nullable | bloque informativo de facturacion |
| `tariff_name` | texto nullable | bloque informativo de facturacion |
| `meter_number` | texto nullable | bloque informativo de facturacion |
| `connection_type` | texto nullable | bloque informativo de facturacion |

Clave unica: proveedor y codigo de cliente.

Los cinco campos secundarios marcados como `nullable` son independientes. Si
el portal omite uno, se conserva como nulo sin cancelar la sincronizacion ni
inventar un valor. `provider_id` y `customer_code` mantienen la identidad
esencial de la cuenta.

## `billing_records`

Periodo, numero de recibo, consumo en m3, lectura promedio, importe del mes,
meses atrasados, deuda anterior y total. Clave natural: proveedor, cliente y
numero de recibo.

## `payment_records`

Fecha, centro, ano, mes, tipo de comprobante, numero, importe y detalle. Clave
natural: proveedor, cliente, comprobante, fecha e importe.

## `synchronization_metadata`

Ultimo intento, ultima sincronizacion correcta, estado, codigo de error
sanitizado y conteos de recibos/pagos insertados o actualizados.

## Esquema y migraciones

La version actual del esquema es `1`. `WaterDatabaseSchema.version` es la
fuente de verdad. Una version futura debe agregar una migracion explicita y
pruebas de actualizacion; nunca debe borrar silenciosamente datos existentes.
