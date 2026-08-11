# Estimación de consumo e importe — Especificación

## Objetivo

Añadir a Inicio, debajo de `Próximas fechas`, una sección informativa llamada
`Tu consumo estimado`. A partir del historial mensual real y local del
suministro activo, ConsumoPlus estimará únicamente el siguiente periodo para:

- consumo de Agua en m³ e importe mensual en soles;
- consumo de Electricidad en kWh e importe mensual en soles.

La información principal será un rango orientativo. Todo se calculará
localmente en Dart y no modificará scraping, parsers, autenticación, cookies,
SQLCipher, migraciones ni sincronización.

## Enfoques considerados

1. Un único promedio fijo: mínimo y estable, pero no se adapta a tendencias.
2. Un modelo elegido una vez: explicable, pero queda obsoleto al crecer el
   historial.
3. Cuatro modelos simples con selección mensual por MAE mediante validación
   retrospectiva: mantiene interpretabilidad y se adapta sin aprendizaje
   remoto.

Se adopta el tercer enfoque. Consumo e importe son dos series independientes y
pueden elegir modelos ganadores diferentes.

## Alcance del suministro y datos

- Solo se utiliza el suministro activo de cada servicio.
- Nunca se mezclan códigos EPS, contratos Electrosur, viviendas o servicios.
- Continúa admitiéndose un suministro activo por servicio; múltiples viviendas
  quedan fuera de alcance.
- Se seleccionan como máximo los 12 periodos válidos más recientes.
- Los periodos se deduplican, se ordenan cronológicamente y conservan su fecha
  mensual real.
- Si dos registros representan el mismo periodo, se conserva el sincronizado
  más recientemente; un empate se resuelve mediante su clave natural para que
  el resultado no dependa del orden de entrada.
- Solo son válidos los meses `1...12` y los consumos/importes finitos y no
  negativos.
- No se inventan meses, no se interpolan huecos y no se rellenan valores con
  cero.
- Agua usa `consumptionCubicMeters` y `monthlyChargeCents`.
- Electricidad usa `consumptionWh`, convertido a kWh para cálculo y
  presentación, y `monthlyChargeCents`.
- Deudas, mora, saldos, totales acumulados y pagos quedan excluidos.

## Disponibilidad

- Menos de 6 periodos válidos: estado `insufficient`, sin números ni tendencia;
  se muestra `Aún necesitamos más historial` y el mínimo requerido.
- Entre 6 y 11: estado `preliminary` y texto `Estimación preliminar`.
- Con 12: estado `sufficient` y texto
  `Basado en 12 meses de historial`.
- Si los huecos temporales impiden suficientes comparaciones comunes, se
  muestra `Historial insuficiente o irregular para estimar`.

## Modelos candidatos

Para cada serie se evalúan independientemente:

1. Naive: `ŷ(t+1) = y(t)`.
2. Promedio móvil simple de tres periodos:
   `ŷ(t+1) = (y(t) + y(t-1) + y(t-2)) / 3`.
3. Promedio móvil ponderado de tres periodos:
   `ŷ(t+1) = (1*y(t-2) + 2*y(t-1) + 3*y(t)) / 6`.
4. Regresión lineal por mínimos cuadrados: `y = a + bx`, donde `x` representa
   el índice mensual real y solo se proyecta un mes.

Los modelos móviles requieren los tres meses reales inmediatamente anteriores
y consecutivos. La regresión respeta la distancia mensual real. Ningún modelo
trata observaciones separadas por huecos como meses contiguos.

Las salidas matemáticas negativas se limitan a cero tanto durante la
evaluación como en la proyección final, porque consumo e importe mensual no
admiten resultados negativos.

## Validación retrospectiva y selección

Se aplica rolling-origin sobre los mismos periodos comparables para los cuatro
modelos. Con 12 meses consecutivos:

- M1–M3 predicen M4;
- se amplía el origen un mes cada vez;
- M1–M11 predicen M12.

Esto produce nueve errores comparables por modelo. Para historiales irregulares
solo se conservan los objetivos para los que los cuatro candidatos pueden
predecir respetando sus reglas temporales.

Se requieren al menos tres objetivos retrospectivos comunes y que el modelo
ganador pueda proyectar válidamente el mes posterior al último periodo real.
Los modelos móviles requieren una cola de tres meses consecutivos; la regresión
puede conservar huecos anteriores mediante la distancia calendario. Si el
ganador no puede proyectar, aunque existan seis registros, el estado será
`Historial insuficiente o irregular para estimar`. Con seis meses consecutivos
existen exactamente tres objetivos comunes: M4, M5 y M6.

Para cada modelo:

`MAE = promedio(abs(real - predicho))`

Gana el menor MAE. Un candidato se considera prácticamente equivalente al
mejor cuando su diferencia no supera el 1 % del menor MAE, con `1e-9` como
tolerancia mínima para el caso cero. Entre equivalentes se usa el orden
estable: Naive, promedio móvil simple, promedio móvil ponderado y regresión
lineal. La regla es determinista y favorece la opción más simple.

El ganador se vuelve a ajustar con todos los periodos válidos dentro de la
ventana máxima y predice únicamente el mes siguiente al último periodo real.
Cada nuevo periodo vuelve a ejecutar todo el proceso.

## Resultado y rangos

El dominio devuelve un `ForecastResult` tipado con periodo, muestra, estado,
resultados de consumo e importe, modelos, MAE, variaciones y tendencia.

Cada rango se calcula con el MAE retrospectivo del ganador:

- `lower = max(0, central - MAE)`;
- `upper = max(0, central + MAE)`.

Se llama `Rango estimado`, no intervalo de confianza. Un historial variable
mantiene un rango amplio; no se estrecha artificialmente. Cuando el MAE sea
alto en relación con la magnitud de la serie, la UI podrá indicar que existe
bastante variación. El criterio será `MAE / promedio de valores reales >= 25 %`;
si el promedio es cero no se mostrará ese aviso.

## Variaciones y tendencia

Consumo e importe calculan por separado:

`((estimación central - último real) / último real) * 100`

Cuando el último valor es cero, la variación queda ausente. La tendencia usa
exclusivamente la variación de consumo:

- `<= -5 %`: `🙂 Tendencia favorable`;
- `> -5 %` y `< +5 %`: `😐 Consumo estable`;
- `>= +5 %`: `🙁 Tendencia al alza`.

El porcentaje monetario nunca afecta la clasificación.

## Arquitectura y flujo

Una fuente local específica de pronóstico entregará snapshots completos ya
asociados al suministro activo. Reutilizará la misma base cifrada y los mismos
data sources locales que `Próximas fechas`, sin cambiar ese flujo existente ni
realizar accesos remotos. El flujo será:

`snapshots locales → preparación de series → modelos puros → rolling-origin → selección por MAE → ForecastResult → controlador de Inicio → widgets`

Las unidades serán pequeñas y separadas:

- observación y periodo mensual tipados;
- modelos matemáticos puros con una interfaz común;
- evaluador MAE y selector determinista;
- preparador de series por servicio;
- calculador coordinador de consumo e importe;
- estado y controlador de pronóstico consumidos por Inicio;
- `ForecastSection` y `ServiceForecastCard` únicamente de presentación.

No se añade SQL a Views ni matemática a widgets. `HomeDependencies` comparte
la conexión cifrada, mientras los controladores de fechas y pronóstico siguen
siendo unidades independientes y actualizables.

## Inicio y presentación

La sección aparece debajo de `Próximas fechas`:

- ningún servicio conectado: no aparece;
- solo Agua: una tarjeta azul;
- solo Electricidad: una tarjeta ámbar;
- ambos: Agua y Electricidad, en ese orden.

Las tarjetas comparten superficie, radio, padding, tipografía y jerarquía con
`Próximas fechas`. El color se usa como acento, no como fondo completo. Son
puramente informativas: sin botón, `InkWell`, chevron ni acción de navegación.

Cada tarjeta muestra servicio/proveedor, tendencia, periodo estimado, rango de
consumo, rango de pago, variación principal de consumo, variación secundaria
del importe, cantidad de meses y `Estimación orientativa`. Los estados sin
datos no muestran caritas favorables o desfavorables.

Las etiquetas semánticas describen servicio, periodo, rangos, tendencia y
carácter orientativo sin depender del color. El contenido debe funcionar a 320
px y con escalas de texto 1.3x y 1.8x.

Agua presenta m³ con hasta una cifra decimal; Electricidad presenta kWh con
hasta una cifra decimal; los soles usan dos decimales. Los porcentajes se
redondean al entero más cercano y usan `≈` para evitar falsa precisión.

## Errores, seguridad y privacidad

Una lectura o cálculo fallido es suplementario y no bloquea Inicio. No se
inventan resultados. No se registran históricos, importes, identificadores,
datos personales ni pronósticos. Todos los fixtures son ficticios.

Las estimaciones son orientativas y no garantizan el consumo ni el importe
futuro.

## Pruebas y validación

Las pruebas puras cubrirán los cuatro modelos, MAE, nueve orígenes comunes,
selección y desempate, series constante/creciente/decreciente/variable,
6/7–11/12/más de 12 periodos, cambio diciembre–enero, huecos, inválidos, ceros,
clamp, tendencias y ganadores independientes.

Las pruebas de UI cubrirán visibilidad por conexión, insuficiente, preliminar,
12 meses, unidades y moneda, independencia de la carita, ausencia de
navegación, semántica, suministro activo, pantalla pequeña y text scaling.

Primero se ejecutarán los tests matemáticos dirigidos. Al final se ejecutarán
una sola vez `dart format .`, `flutter analyze`, `flutter test` y
`git diff --check`, seguidos de un único `flutter build apk --debug`. No se
creará commit, merge ni push.
