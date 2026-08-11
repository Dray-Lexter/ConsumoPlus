# Próximas fechas en Inicio — Especificación

## Objetivo

Añadir debajo de las tarjetas principales de Inicio una sección informativa
`Próximas fechas`. Solo aparecerá cuando exista al menos una cuenta local de
Agua o Electricidad. No será navegable y no realizará conexiones remotas.

## Alcance y restricciones

- Mantener la dirección visual `Hogar claro` y la composición actual de Inicio.
- Agua usa azul; Electricidad usa ámbar/naranja.
- No modificar scraping, parsers, autenticación, SQLCipher ni su esquema.
- No agregar notificaciones, alarmas, calendario, servicios en segundo plano,
  predicciones ni sincronización automática.
- Usar únicamente datos locales cifrados ya existentes y fechas ficticias en
  las pruebas.
- No crear commit, merge ni push.

## Arquitectura

Inicio recibirá una fábrica de `UpcomingDatesController`. El controlador leerá
en paralelo los snapshots locales mediante una fuente de datos de solo lectura,
construida sobre `WaterLocalDataSource` y `ElectricityLocalDataSource`. La View
no conocerá SQL, repositorios remotos ni credenciales.

`UpcomingDatesCalculator` será una unidad pura con reloj inyectable. Resolverá
fechas locales sin hora, suma de meses calendario, textos temporales y progreso.
Los resultados serán modelos de presentación inmutables que los widgets podrán
renderizar sin repetir reglas por proveedor.

## Visibilidad y actualización

- Ninguna cuenta local: no renderizar título, tarjetas ni placeholders.
- Solo Agua: renderizar únicamente Agua.
- Solo Electricidad: renderizar únicamente Electricidad.
- Ambas: renderizar Agua y Electricidad, en ese orden.
- Recalcular al abrir Inicio, al volver de una pantalla de servicio y al recibir
  `AppLifecycleState.resumed`.
- Una lectura local fallida no bloquea Inicio ni muestra datos inventados; la
  sección permanece oculta durante ese intento.

## Reglas de Agua

`WaterBillingSchedule` centraliza `expectedIssueDay = 15` y
`expectedDueDay = 25`. Cada fecha se calcula como la próxima ocurrencia, hoy o
en el futuro, avanzando un mes calendario cuando ya pasó.

Los textos serán siempre:

- `Próximo recibo estimado`.
- `Próximo vencimiento estimado`.

No se presentarán como fechas confirmadas por EPS Tacna.

## Reglas de Electricidad

El estado de cuenta local más reciente aporta `issueDate` y `dueDate`:

- `dueDate` es oficial y se muestra como `Vence tu recibo` mientras la fecha
  actual sea anterior a `issueDate + 1 mes calendario`.
- Si `dueDate` ya pasó dentro de ese intervalo, se muestra neutralmente
  `Venció hace X días`, sin inferir deuda o impago.
- Al alcanzar `issueDate + 1 mes calendario`, la fecha oficial anterior se
  considera antigua y se reemplaza por `Vencimiento pendiente de actualización`
  con `Actualiza Electrosur para consultar la fecha del nuevo recibo.` No se
  muestra una fecha ni barra inventada para ese indicador.
- La próxima emisión se estima sumando meses calendario a `issueDate` hasta
  obtener una fecha igual o posterior a hoy. Se etiqueta
  `Próximo recibo estimado`.
- Si falta `issueDate`, no se inventa la emisión. Si falta o no es vigente
  `dueDate`, se usa el aviso pendiente de actualización.

## Cálculo de fechas y progreso

Todas las entradas se convierten a `DateTime(año, mes, día)` local. La suma de
mes calendario conserva el día cuando existe y lo limita al último día del mes
destino. Esto cubre diciembre/enero, febrero, años bisiestos y meses de 30/31
días.

Para ciclos mensuales, el progreso es:

`días transcurridos desde el inicio / días totales hasta el evento`

El inicio es la ocurrencia equivalente del mes anterior. Para un vencimiento
oficial de Electrosur, el inicio es `issueDate` y el final es `dueDate`. El
resultado siempre se limita a `0.0...1.0`. No se muestra porcentaje numérico.

## Textos temporales

- Futuro, un día: `Falta 1 día`.
- Futuro, más de un día: `Faltan X días`.
- Emisión hoy: `Esperado hoy`.
- Vencimiento hoy: `Vence hoy`.
- Vencimiento oficial pasado y vigente: `Venció hace 1 día` o
  `Venció hace X días`.
- Una emisión estimada pasada avanza al ciclo mensual siguiente.

Las fechas visibles usan formato corto como `15 ago`; las etiquetas semánticas
usan la fecha completa en español.

## Presentación y accesibilidad

`UpcomingDatesSection` contiene el título y las tarjetas disponibles.
`ServiceScheduleCard` agrupa icono, servicio, proveedor y ambos indicadores.
`ScheduleProgressRow` muestra etiqueta, fecha, distancia temporal y una barra
fina no interactiva cuando existe un ciclo válido.

Cada indicador tendrá una única descripción semántica completa, por ejemplo:
`Agua. Próximo recibo estimado el 15 de agosto de 2026. Faltan 4 días.` El
significado nunca dependerá solo del color. El diseño debe permanecer
desplazable a 320 px de ancho con escalas de texto 1.3x y 1.8x.

## Pruebas y validación

Se cubrirán: ninguna/una/ambas cuentas; antes, hoy y pasado; singular/plural;
cambio de mes y año; febrero y bisiesto; días 15/25; fechas oficiales de
Electrosur; siguiente emisión estimada; vencimiento antiguo; progreso limitado;
semántica; pantalla pequeña; texto ampliado; recarga al volver y al reanudar.

Validación final: `dart format .`, `flutter analyze`, `flutter test`,
`git diff --check` y un único APK debug.
