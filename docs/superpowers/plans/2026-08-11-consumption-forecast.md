# Consumption Forecast Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Estimar localmente el rango de consumo e importe del siguiente mes para el suministro activo de Agua y Electricidad y mostrarlo en Inicio.

**Architecture:** Un dominio Dart puro prepara periodos, ejecuta cuatro modelos, los compara mediante rolling-origin y MAE y produce resultados tipados. Un controlador independiente de pronóstico lee snapshots locales cifrados mediante los data sources existentes; Inicio presenta tarjetas compartidas sin navegación.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`, SQLCipher existente a través de los local data sources, `flutter_test`; sin dependencias nuevas.

## Global Constraints

- No modificar scraping, parsers, autenticación, cookies, contratos HTTP, SQLCipher, migraciones ni sincronización.
- Calcular todo localmente en Dart y no registrar históricos, importes, identificadores ni pronósticos.
- Usar solo el suministro activo, hasta 12 periodos reales, sin inventar meses ni ceros.
- Separar matemáticamente consumo e importe y usar únicamente cargos mensuales, nunca deuda o pagos.
- Menos de 6 periodos no produce números; 6–11 es preliminar; 12 es suficiente.
- Con 12 meses consecutivos evaluar los cuatro modelos sobre los mismos nueve objetivos M4...M12.
- La sección de Inicio es informativa, no navegable y aparece solo para servicios conectados.
- No añadir paquetes, commit, merge ni push.
- Generar un solo APK y únicamente después de todas las verificaciones.

---

### Task 1: Periodos, resultados tipados y cuatro modelos puros

**Files:**
- Create: `lib/features/home/domain/forecast/month_period.dart`
- Create: `lib/features/home/domain/forecast/forecast_models.dart`
- Create: `lib/features/home/domain/forecast/forecasting_model.dart`
- Test: `test/features/home/domain/forecast/forecasting_models_test.dart`

**Interfaces:**
- Produces: `MonthPeriod`, `TimeSeriesPoint`, `ForecastModelType`, `ForecastingModel`, `forecastingModels`, `SeriesForecast`, `ForecastStatus`, `TrendClassification`, `ServiceForecast`.
- `ForecastingModel.predict(List<TimeSeriesPoint> training, MonthPeriod target)` returns a non-negative `double` or throws `ForecastUnavailableException` when temporal prerequisites are not met.

- [ ] **Step 1: Write failing period and model tests**

Cover month ordinals and `2026-12 → 2027-01`; Naive; SMA(3); WMA weights 1/2/3; regression on constant, increasing and decreasing series; non-consecutive rejection for moving models; and one-period-only projection.

```dart
expect(const MonthPeriod(2026, 12).next, const MonthPeriod(2027, 1));
expect(naive.predict(points([10, 20, 30]), month(4)), 30);
expect(simple.predict(points([10, 20, 40]), month(4)), closeTo(70 / 3, 1e-9));
expect(weighted.predict(points([10, 20, 40]), month(4)), closeTo(170 / 6, 1e-9));
expect(linear.predict(points([10, 20, 30]), month(4)), closeTo(40, 1e-9));
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run: `flutter test test/features/home/domain/forecast/forecasting_models_test.dart`

Expected: compile failure because the forecast domain does not exist.

- [ ] **Step 3: Implement immutable period/result types and models**

Use the following public shape:

```dart
final class MonthPeriod implements Comparable<MonthPeriod> {
  const MonthPeriod(this.year, this.month);
  final int year;
  final int month;
  int get ordinal => year * 12 + month - 1;
  MonthPeriod get next;
  bool isImmediatelyBefore(MonthPeriod other);
}

final class TimeSeriesPoint {
  const TimeSeriesPoint({required this.period, required this.value});
  final MonthPeriod period;
  final double value;
}

abstract interface class ForecastingModel {
  ForecastModelType get type;
  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target);
  double predict(List<TimeSeriesPoint> training, MonthPeriod target);
}
```

Regression uses `period.ordinal - training.first.period.ordinal` as `x`. Clamp every prediction with `max(0, value)`.

- [ ] **Step 4: Run focused tests and confirm GREEN**

Run: `flutter test test/features/home/domain/forecast/forecasting_models_test.dart`

Expected: all model tests pass.

---

### Task 2: Rolling-origin, MAE, selección y rango

**Files:**
- Create: `lib/features/home/domain/forecast/forecast_engine.dart`
- Test: `test/features/home/domain/forecast/forecast_engine_test.dart`

**Interfaces:**
- Consumes: `TimeSeriesPoint`, `MonthPeriod`, `ForecastingModel`, `forecastingModels`.
- Produces: `ForecastEngine.forecast(List<TimeSeriesPoint>) → SeriesForecast?`, `meanAbsoluteError`, and deterministic model selection.

- [ ] **Step 1: Write failing engine tests**

Assert: nine comparable predictions for 12 consecutive points; exactly three for six; common origins only; MAE formula; lowest MAE wins; 1 % equivalent-MAE tie chooses simpler order; constant series chooses Naive; range is `central ± MAE`; lower bound and negative model outputs clamp to zero; zero last value yields null variation; irregular history with fewer than three common origins returns null; only the selected winner must support the final target; and variable history sets the 25 % flag.

```dart
final result = const ForecastEngine().forecast(twelveConsecutivePoints);
expect(result!.evaluationCount, 9);
expect(result.lower, max(0, result.central - result.mae));
expect(result.upper, result.central + result.mae);
```

- [ ] **Step 2: Run engine tests and confirm RED**

Run: `flutter test test/features/home/domain/forecast/forecast_engine_test.dart`

Expected: compile failure for missing `ForecastEngine`.

- [ ] **Step 3: Implement fair rolling-origin evaluation**

For every target index from 3 onward, create `training = points.sublist(0, index)`. Keep the target only if all four models return `canPredict == true`. Evaluate every model on that identical target list, clamp predictions before computing errors, and require at least three targets.

```dart
double meanAbsoluteError(Iterable<double> errors) =>
    errors.reduce((a, b) => a + b) / errors.length;

final tolerance = max(1e-9, bestMae.abs() * 0.01);
```

Choose the first model in `[naive, simpleMovingAverage, weightedMovingAverage, linearRegression]` whose MAE is within tolerance of the minimum. Refit it over all points and predict `points.last.period.next` only.

- [ ] **Step 4: Run model and engine tests and confirm GREEN**

Run: `flutter test test/features/home/domain/forecast`

Expected: all pure mathematical tests pass.

---

### Task 3: Preparación de los historiales activos y pronóstico por servicio

**Files:**
- Create: `lib/features/home/domain/forecast/service_forecast_calculator.dart`
- Create: `lib/features/home/application/forecast_source.dart`
- Create: `lib/features/home/application/local_forecast_source.dart`
- Test: `test/features/home/domain/forecast/service_forecast_calculator_test.dart`
- Test: `test/features/home/application/local_forecast_source_test.dart`

**Interfaces:**
- Produces: `MonthlyUtilityObservation`, `ServiceForecastInput`, `ForecastCalculator.build(List<ServiceForecastInput>)` and `ForecastSource.load()`.
- `LocalForecastSource` accepts `WaterSnapshotLoader` and `ElectricitySnapshotLoader` and returns only records matching the snapshot account identifier.

- [ ] **Step 1: Write failing preparation tests**

Cover: sort independent of portal order; same-period deduplication by newest `synchronizedAt` and natural-key tie; invalid month/non-finite/negative filtering; maximum latest 12; less than 6; 6–11 preliminary; 12 sufficient; December–January; consumption/cost independent winners; trend boundaries `-5/+5`; and no variation when the latest real value is zero.

```dart
expect(calculator.build([inputWithFiveMonths]).single.status,
    ForecastStatus.insufficient);
expect(calculator.build([inputWithTwelveMonths]).single.sampleCount, 12);
expect(result.consumption.model, isNot(result.cost.model));
```

- [ ] **Step 2: Run calculator/source tests and confirm RED**

Run: `flutter test test/features/home/domain/forecast/service_forecast_calculator_test.dart test/features/home/application/local_forecast_source_test.dart`

Expected: missing calculator and source types.

- [ ] **Step 3: Implement deterministic preparation and mapping**

Map Water from `billingRecords` using m³ and `monthlyChargeCents`; map Electricity from `consumptionRecords` using `consumptionWh / 1000.0` and `monthlyChargeCents`. Reject records whose provider/account keys differ from the active snapshot.

Group by `MonthPeriod`, choose newest synchronization and then lexical `sourceKey`, sort ascending, retain `skip(max(0, length - 12))`, and feed two independent `ForecastEngine` calls. Cost stays in cents in domain and is converted only for presentation.

- [ ] **Step 4: Run all pure forecast and source tests**

Run: `flutter test test/features/home/domain/forecast test/features/home/application/local_forecast_source_test.dart`

Expected: all pass without Flutter widget dependencies in mathematical tests.

---

### Task 4: Controlador, dependencias y actualización de Inicio

**Files:**
- Create: `lib/features/home/application/forecast_controller.dart`
- Create: `lib/features/home/application/forecast_state.dart`
- Modify: `lib/features/home/application/home_dependencies.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/routes/app_router.dart`
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/features/home/application/forecast_controller_test.dart`
- Modify: `test/features/home/home_screen_test.dart`

**Interfaces:**
- Produces: `ForecastControllerFactory`, `ForecastController.refresh()`, `ForecastState.forecasts`.
- Home requires both `createUpcomingDatesController` and `createForecastController` and refreshes both after returning from a service and on app resume.

- [ ] **Step 1: Write failing controller/Home lifecycle tests**

Test controller success, insufficient result and non-blocking local failure. Extend Home tests to verify forecast loading at startup, after returning from a service and on resume.

- [ ] **Step 2: Run controller/Home tests and confirm RED**

Run: `flutter test test/features/home/application/forecast_controller_test.dart test/features/home/home_screen_test.dart`

- [ ] **Step 3: Implement controller and dependency wiring**

`ForecastController.refresh()` preserves current forecasts while loading and becomes empty on failure without surfacing sensitive errors. `HomeDependencies.createForecastController()` opens the shared encrypted database, creates both existing local data sources and injects their `loadLatest` calls into `LocalForecastSource`.

In Home, initialize/dispose/listen exactly like the dates controller and call both refresh methods through a private `_refreshSupplementaryData()`.

- [ ] **Step 4: Run controller, routing and Home tests**

Run: `flutter test test/features/home/application/forecast_controller_test.dart test/features/home/home_screen_test.dart test/features/splash/splash_navigation_test.dart`

Expected: existing navigation remains unchanged and the new controller is supplementary.

---

### Task 5: Tarjetas compartidas, copy, semántica y responsividad

**Files:**
- Create: `lib/features/home/forecast_copy.dart`
- Create: `lib/features/home/presentation/widgets/forecast_section.dart`
- Create: `lib/features/home/presentation/widgets/service_forecast_card.dart`
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/features/home/presentation/forecast_section_test.dart`
- Modify: `test/accessibility/responsive_layout_test.dart`

**Interfaces:**
- Consumes: `List<ServiceForecast>` from `ForecastState`.
- Produces: `ForecastSection(forecasts:)` and `ServiceForecastCard(forecast:)`; neither exposes callbacks.

- [ ] **Step 1: Write failing widget tests**

Cover no section, Water only, Electricity only, both, insufficient/irregular, preliminary, 12 months, m³/kWh/S/, trend based only on consumption, monetary variation not changing the face, no `InkWell`/button/tap semantics, complete semantic label, 320 px, 1.3x and 1.8x scaling.

```dart
expect(find.byKey(const Key('forecastCard-water')), findsOneWidget);
expect(find.byType(InkWell), findsNothing);
expect(semantics.hasAction(SemanticsAction.tap), isFalse);
```

- [ ] **Step 2: Run widget tests and confirm RED**

Run: `flutter test test/features/home/presentation/forecast_section_test.dart`

- [ ] **Step 3: Implement compact harmonized presentation**

Reuse `UtilityType.visual`, `AppColors.surface`, `AppColors.outline`, `AppRadii.md` and centralized spacing. Put `ForecastSection` after `UpcomingDatesSection`. Format Water/Electricity with at most one decimal, currency with two decimals and percentages as rounded integers prefixed by `≈`.

For insufficient data render the neutral title and explanatory text only. For results render trend, predicted Spanish month/year, range rows, variations, history label and `Estimación orientativa`. Add the 25 % variability note only when `isHighlyVariable` is true.

- [ ] **Step 4: Run forecast and accessibility widget tests**

Run: `flutter test test/features/home/presentation/forecast_section_test.dart test/features/home/home_screen_test.dart test/accessibility/responsive_layout_test.dart`

Expected: no overflow and no navigation semantics on forecast cards.

---

### Task 6: Documentación técnica y privacidad

**Files:**
- Create: `docs/forecasting.md`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/data_dictionary.md`
- Modify: `docs/security.md`
- Modify: `test/security/tracked_secret_scan_test.dart` only if the existing scan needs the new tracked files listed explicitly.

**Interfaces:**
- Documents the implemented formulas, nine comparable origins, independent series, deterministic tie, range rule, thresholds, active supply isolation and limitations.

- [ ] **Step 1: Write the predictor document**

Include objective, inputs, 6/12 thresholds, four formulas, rolling-origin, same targets, nine predictions, MAE, 1 % tie, independent winners, `central ± MAE`, ±5 % trend, monthly reselection and gaps. Include verbatim:

`Las estimaciones son orientativas y no garantizan el consumo ni el importe futuro.`

- [ ] **Step 2: Update only affected general documentation**

README mentions the local estimate; architecture records the pure domain/controller/widget boundary; data dictionary documents transient `ForecastResult` as non-persisted; security confirms no external transfer or prediction logging.

- [ ] **Step 3: Run documentation/security-related tests**

Run: `flutter test test/security`

Expected: all fixtures and tracked files remain sanitized.

---

### Task 7: Directed verification, complete suite and single APK

**Files:**
- Verify only; do not modify unless a demonstrated failure belongs to this feature.

- [ ] **Step 1: Run mathematical tests first**

Run: `flutter test test/features/home/domain/forecast`

Expected: all mathematical tests pass.

- [ ] **Step 2: Run final formatting once**

Run: `dart format .`

- [ ] **Step 3: Run final static analysis once**

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 4: Run the complete suite once**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 5: Check whitespace once**

Run: `git diff --check`

Expected: no output.

- [ ] **Step 6: Build exactly one debug APK**

Run: `flutter build apk --debug`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` exists. Record its absolute path and byte size.

- [ ] **Step 7: Report without committing**

Report architecture, formulas, nine origins, fair comparison, MAE, winner/tie, independent consumption/cost, ranges, trend, active-supply isolation, insufficient history, visual components, new/total tests, analyze, diff check, build and APK path. Do not commit, merge or push.
