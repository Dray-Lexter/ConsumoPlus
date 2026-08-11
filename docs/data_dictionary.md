# Diccionario de datos

Los importes se almacenan como céntimos enteros y las marcas de sincronización como milisegundos UTC.

## Agua

Las tablas existentes permanecen sin cambios: `water_accounts`, `billing_records`, `payment_records` y `synchronization_metadata`. Los campos secundarios de `water_accounts` (`service_address`, `service_status`, `tariff_name`, `meter_number`, `connection_type`) son independientes y nullable.

## `electricity_accounts`

| Campo | Tipo | Origen |
| --- | --- | --- |
| `provider_id` | texto | configuración (`electrosur`) |
| `contract_number` | texto | Suministro de Estado de Cuenta |
| `owner_name` | texto | Nombre de Estado de Cuenta |
| `service_address` | texto | Dirección de Estado de Cuenta |
| `tariff_code` | texto | Tarifa; Estado de Cuenta/Suministro |
| `connection_type` | texto nullable | Conexión de Suministro |
| `feeder_type` | texto nullable | Alimentador de Suministro |
| `contracted_power` | texto nullable | Potencia contratada |
| `voltage_level` | texto nullable | Nivel de tensión |
| `meter_number` | texto nullable | Medidor |

Clave única: proveedor y contrato.

## `electricity_account_status`

Periodo `YYYYMM`, facturación del mes, deuda anterior, deuda total, monto pagado, saldo total y fechas opcionales de vencimiento, emisión, lectura y lectura anterior. Clave única: proveedor, contrato y periodo fuente.

## `electricity_consumption_records`

Periodo, tarifa, consumo en Wh y cargo mensual en céntimos. Clave única: proveedor, contrato y periodo fuente. El valor remoto en kWh se multiplica por 1000 sin perder fracciones representables en Wh.

## `electricity_payment_records`

Periodo, fecha, importe en céntimos y centro de pago. La clave única combina proveedor, contrato, periodo, fecha, importe y centro para evitar duplicados sin eliminar pagos distintos.

## `electricity_synchronization_metadata`

Último intento, última sincronización correcta, estado, código de error sanitizado, conteos de consumos/pagos insertados o actualizados y banderas de actualización de Estado de Cuenta y Suministro.

## Esquema y migraciones

`AppDatabaseSchema.version` es `2`. La migración 1→2 crea solo las tablas de Electricidad y conserva íntegramente las tablas y filas de Agua. Una instalación nueva crea ambos conjuntos. Toda versión futura requiere una migración explícita y una prueba que parta del esquema anterior.
