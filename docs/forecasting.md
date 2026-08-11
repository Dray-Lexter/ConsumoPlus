# Pronóstico local de consumo e importe

## Objetivo y alcance

ConsumoPlus estima el consumo y el importe mensual del siguiente periodo del suministro activo de Agua y de Electricidad. El cálculo se ejecuta íntegramente en Dart sobre el historial ya almacenado en SQLCipher. No usa servicios externos, modelos remotos ni inteligencia artificial.

Las estimaciones son orientativas y no garantizan el consumo ni el importe futuro.

## Datos de entrada

Cada servicio se procesa por separado y solo con el identificador activo:

- Agua: código de suministro EPS Tacna, consumo mensual en m³ e importe facturado del mes en céntimos.
- Electricidad: contrato Electrosur, consumo mensual convertido de Wh a kWh e importe facturado del mes en céntimos.

No se usan deuda anterior, saldo acumulado ni pagos. Los registros se validan, se deduplican por periodo y se ordenan cronológicamente. Ante dos registros del mismo periodo se elige el de sincronización más reciente; si las marcas coinciden, se aplica un desempate léxico determinista por clave de origen.

La ventana inicial contiene como máximo los 12 periodos válidos más recientes. No se inventan meses, no se interpolan valores y los huecos no se rellenan con cero. Con menos de 6 periodos no se presenta un rango numérico.

## Modelos candidatos

Para una serie `y` se evalúan cuatro modelos matemáticos de corto plazo:

1. Último valor o naive: `ŷ(t+1) = y(t)`.
2. Promedio móvil simple de 3 periodos: `ŷ(t+1) = (y(t-2) + y(t-1) + y(t)) / 3`.
3. Promedio móvil ponderado de 3 periodos: `ŷ(t+1) = (y(t-2) + 2y(t-1) + 3y(t)) / 6`.
4. Regresión lineal por mínimos cuadrados: `y = a + bx`, usando como `x` la posición real del mes en el calendario y proyectando solo el mes siguiente.

Los dos modelos móviles exigen tres observaciones mensuales consecutivas. La regresión conserva la distancia temporal real entre observaciones. Toda predicción negativa se limita a cero antes de evaluarla o presentarla.

## Validación retrospectiva y MAE

La selección usa validación retrospectiva de origen móvil. En cada origen solo se admite un periodo objetivo si los cuatro candidatos pueden producir una predicción temporalmente válida. Así, todos se comparan exactamente contra los mismos valores reales.

Con 12 meses consecutivos, el primer origen común usa `M1–M3` para predecir `M4`. El proceso continúa hasta usar `M1–M11` para predecir `M12`. Por tanto, cada modelo acumula exactamente 9 evaluaciones comparables.

Si existen huecos, la cantidad de evaluaciones puede ser menor. Se requieren al menos 3 objetivos comunes; de lo contrario, el historial se considera insuficiente o irregular.

Para cada modelo se calcula el error absoluto medio:

```text
MAE = suma(|valor real - valor estimado|) / número de evaluaciones comunes
```

Gana el menor MAE. Cuando dos MAE están dentro del 1 % del mejor —con tolerancia numérica mínima de `1e-9`— se prefiere el modelo más simple, en este orden determinista: último valor, promedio móvil simple, promedio móvil ponderado y regresión lineal.

Después de elegir el ganador se vuelve a ajustar con todos los periodos válidos de la ventana y se estima únicamente el periodo siguiente. La competencia se repite cada vez que llega un nuevo mes real, por lo que el modelo ganador puede cambiar.

## Dos pronósticos independientes

Consumo e importe recorren de forma independiente la validación, el cálculo de MAE y la selección. Un servicio puede elegir, por ejemplo, promedio ponderado para consumo y regresión para importe. No se combinan m³ o kWh con soles.

Para cada serie, el rango orientativo se calcula así:

```text
límite inferior = máximo(0, estimación central - MAE del ganador)
límite superior = estimación central + MAE del ganador
```

Este resultado se denomina rango estimado, no intervalo de confianza. Cuando `MAE / media histórica >= 25 %`, la interfaz advierte que la variación histórica amplía el rango.

## Tendencia

La tendencia depende exclusivamente de la estimación central de consumo respecto del último consumo real:

```text
variación = ((estimación central - último valor) / último valor) * 100
```

- Hasta `-5 %`: tendencia favorable.
- Mayor que `-5 %` y menor que `+5 %`: consumo estable.
- Desde `+5 %`: tendencia al alza.

Si el último consumo es cero, no se calcula un porcentaje. La variación monetaria se calcula y presenta por separado, pero nunca modifica la tendencia.

## Estados y limitaciones

- Menos de 6 periodos: historial insuficiente, sin cifras estimadas.
- De 6 a 11: estimación preliminar, siempre que existan al menos 3 evaluaciones comunes y el modelo ganador pueda proyectar válidamente el siguiente periodo.
- 12 periodos: estimación basada en 12 meses de historial.
- Huecos incompatibles con las reglas temporales: historial insuficiente o irregular.
- El periodo pronosticado es el mes calendario posterior al último periodo real, incluso en el cambio de diciembre a enero.
- La ventana de 12 meses y los umbrales son parámetros de dominio ampliables en versiones futuras.
- Los modelos capturan patrones simples de corto plazo; no incorporan clima, cambios tarifarios, ocupación de la vivienda ni eventos extraordinarios.

## Privacidad y actualización

Inicio consulta las fuentes locales existentes y filtra por proveedor e identificador activo antes de construir las series. La sección se recalcula al entrar, al regresar de Agua o Electricidad y al reanudar la aplicación. No persiste resultados derivados ni registra consumos, importes o datos del suministro en logs.
