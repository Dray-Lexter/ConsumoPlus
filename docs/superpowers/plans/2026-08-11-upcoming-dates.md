# Próximas fechas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar en Inicio las próximas fechas informativas de las cuentas locales conectadas de Agua y Electricidad.

**Architecture:** Un calculador puro convierte una entrada mínima de cuentas y fechas en modelos de presentación inmutables. Un controlador de Inicio carga únicamente snapshots locales cifrados y recalcula al abrir, volver o reanudar; tres widgets compartidos presentan el resultado sin conocer almacenamiento ni reglas de proveedor.

**Tech Stack:** Flutter, Dart, Material 3, `ChangeNotifier`, almacenamiento SQLCipher existente y `flutter_test`.

## Global Constraints

- No modificar scraping, parsers, autenticación, SQLCipher ni el esquema de base de datos.
- No añadir paquetes, notificaciones, alarmas, calendario, background services ni conexiones automáticas.
- Mantener `Hogar claro`, Agua azul, Electricidad ámbar y la composición actual de Inicio.
- Usar fechas locales sin hora, suma de mes calendario y fixtures completamente ficticios.
- Ejecutar TDD con RED comprobado antes de cada implementación.
- No crear commit, merge ni push.

---

### Task 1: Modelos y aritmética de calendario

**Files:**
- Create: `lib/features/home/domain/water_billing_schedule.dart`
- Create: `lib/features/home/domain/upcoming_dates_models.dart`
- Create: `lib/features/home/domain/upcoming_dates_calculator.dart`
- Create: `test/features/home/domain/upcoming_dates_calculator_test.dart`

**Interfaces:**
- Produces: `WaterBillingSchedule`, `UpcomingDatesInput`, `ServiceSchedule`,
  `ScheduleIndicator`, `UpcomingDatesCalculator.build(...)`,
  `addCalendarMonths(...)`.

- [ ] **Step 1: Write failing date-arithmetic tests**

```dart
expect(addCalendarMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
expect(addCalendarMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
expect(addCalendarMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test --no-pub test/features/home/domain/upcoming_dates_calculator_test.dart`

Expected: FAIL because the calendar API does not exist.

- [ ] **Step 3: Implement immutable models and calendar helpers**

```dart
class WaterBillingSchedule {
  const WaterBillingSchedule({
    required this.expectedIssueDay,
    required this.expectedDueDay,
  });
  final int expectedIssueDay;
  final int expectedDueDay;
}

DateTime addCalendarMonths(DateTime value, int months);
DateTime localDate(DateTime value);
```

Use a year/month index and clamp the source day to the last valid day of the
destination month.

- [ ] **Step 4: Add failing Water schedule tests**

Use `now = DateTime(2026, 8, 11)` and assert 15/08, 25/08, `Faltan 4 días`,
`Faltan 14 días`, estimated labels and progress in `0.0...1.0`. Add cases for
the event today, the event already passed, month rollover and singular text.

- [ ] **Step 5: Implement Water calculation and verify GREEN**

`UpcomingDatesCalculator.build` consumes:

```dart
class UpcomingDatesInput {
  const UpcomingDatesInput({
    required this.waterConnected,
    required this.electricityConnected,
    this.electricityIssueDate,
    this.electricityDueDate,
  });
}
```

For Water, return two estimated indicators only when `waterConnected` is true.

- [ ] **Step 6: Add failing Electrosur tests**

Assert official due date, past neutral due date, stale boundary exactly at
`issueDate + 1 month`, estimated next issue, repeated estimated cycles, missing
dates and December/January behavior.

- [ ] **Step 7: Implement Electrosur rules and verify GREEN**

At the stale boundary create a pending indicator with no date/progress and the
exact secondary text approved by the user. Never derive a new official due date.

### Task 2: Lectura local y controlador de Inicio

**Files:**
- Create: `lib/features/home/application/upcoming_dates_source.dart`
- Create: `lib/features/home/application/upcoming_dates_state.dart`
- Create: `lib/features/home/application/upcoming_dates_controller.dart`
- Create: `lib/features/home/application/home_dependencies.dart`
- Modify: `lib/app/app_dependencies.dart`
- Test: `test/features/home/application/upcoming_dates_controller_test.dart`

**Interfaces:**
- Consumes: `WaterLocalDataSource.loadLatest`,
  `ElectricityLocalDataSource.loadLatest`, `UpcomingDatesCalculator`.
- Produces: `UpcomingDatesControllerFactory`,
  `UpcomingDatesController.refresh()`, `UpcomingDatesState.schedules`.

- [ ] **Step 1: Write failing controller tests**

```dart
final source = _FakeUpcomingDatesSource(
  const UpcomingDatesInput(waterConnected: true, electricityConnected: false),
);
final controller = UpcomingDatesController(
  source: source,
  clock: () => DateTime(2026, 8, 11),
);
await controller.refresh();
expect(controller.state.schedules, hasLength(1));
```

Also assert both loads are represented, refresh uses a new clock value, and a
source failure results in an empty non-blocking state.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test --no-pub test/features/home/application/upcoming_dates_controller_test.dart`

- [ ] **Step 3: Implement source, state and controller**

```dart
abstract interface class UpcomingDatesSource {
  Future<UpcomingDatesInput> load();
}

typedef UpcomingDatesControllerFactory = Future<UpcomingDatesController>
    Function();
```

`HomeDependencies.createUpcomingDatesController` opens the existing shared
database, loads both provider snapshots in parallel and maps only connection
presence plus `issueDate`/`dueDate`. It must not instantiate remote sources.

- [ ] **Step 4: Run controller and existing local-data tests**

Run: `flutter test --no-pub test/features/home/application/upcoming_dates_controller_test.dart test/features/water/data/local/water_local_data_source_test.dart test/features/electricity/data/local/electricity_local_data_source_test.dart`

Expected: PASS without schema or migration changes.

### Task 3: Componentes visuales reutilizables

**Files:**
- Create: `lib/features/home/presentation/widgets/upcoming_dates_section.dart`
- Create: `lib/features/home/presentation/widgets/service_schedule_card.dart`
- Create: `lib/features/home/presentation/widgets/schedule_progress_row.dart`
- Create: `test/features/home/presentation/upcoming_dates_section_test.dart`

**Interfaces:**
- Consumes: `ServiceSchedule`, `ScheduleIndicator`, centralized utility visual
  identity and system-design constants.
- Produces: `UpcomingDatesSection`, `ServiceScheduleCard`,
  `ScheduleProgressRow`.

- [ ] **Step 1: Write failing visibility tests**

Render zero, Water-only, Electricity-only and both schedule lists. Assert that
zero schedules render neither `Próximas fechas` nor service cards; non-empty
lists render exactly the expected services.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test --no-pub test/features/home/presentation/upcoming_dates_section_test.dart`

- [ ] **Step 3: Implement compact non-interactive widgets**

Use one service card with both rows, no `InkWell`, `GestureDetector`, button
semantics or navigation. Apply `UtilityType.visual.accent`, existing spacing,
radii and typography. Render a thin `LinearProgressIndicator` only when the
indicator has progress.

- [ ] **Step 4: Add semantics and responsive tests**

Assert the full Spanish semantics label, absence of tap actions, a 320x640
viewport, and text scales 1.3 and 1.8 without overflow.

- [ ] **Step 5: Run and verify GREEN**

Run: `flutter test --no-pub test/features/home/presentation/upcoming_dates_section_test.dart`

### Task 4: Integración y recálculo en Inicio

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/app/routes/app_router.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/config/app_copy.dart`
- Modify: `test/features/home/home_screen_test.dart`
- Modify: `test/accessibility/responsive_layout_test.dart`

**Interfaces:**
- Consumes: `UpcomingDatesControllerFactory`, `UpcomingDatesSection`.
- Produces: carga al abrir, recarga después de navegación y recarga en
  `AppLifecycleState.resumed`.

- [ ] **Step 1: Write failing Home lifecycle tests**

Use a counting fake source. Assert one load at startup, a second after awaiting
provider navigation and another after:

```dart
tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
await tester.pump();
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test --no-pub test/features/home/home_screen_test.dart`

- [ ] **Step 3: Convert Home to lifecycle-aware state**

Create/dispose the controller in `HomeScreen`, subscribe with
`WidgetsBindingObserver`, call `refresh()` after provider/settings navigation
returns, and insert `UpcomingDatesSection` after all provider cards. Preserve
the existing header, welcome, explanation and cards.

- [ ] **Step 4: Wire production dependencies**

Pass `AppDependencies.createUpcomingDatesController` through `ConsumoPlusApp`
and `AppRouter`. Keep all existing Water/Electricity factories unchanged.

- [ ] **Step 5: Run Home and accessibility tests**

Run: `flutter test --no-pub test/features/home/home_screen_test.dart test/features/home/presentation/upcoming_dates_section_test.dart test/accessibility/responsive_layout_test.dart`

Expected: PASS, including 320 px and 1.8x text.

### Task 5: Focused regression and quality checks

**Files:**
- Modify only files already listed if a demonstrated regression requires it.

- [ ] **Step 1: Run focused feature tests**

Run: `flutter test --no-pub test/features/home`

- [ ] **Step 2: Run Water/Electricity presentation regressions**

Run: `flutter test --no-pub test/features/water/presentation test/features/electricity/presentation`

- [ ] **Step 3: Scan the diff scope**

Run: `git diff --name-only` and confirm no parser, remote source, database
schema or migration file changed.

### Task 6: Final validation and one debug APK

**Files:**
- Generated, ignored: `build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 1: Format**

Run: `dart format .`

- [ ] **Step 2: Analyze**

Run: `flutter analyze`

- [ ] **Step 3: Run the complete suite**

Run: `flutter test`

- [ ] **Step 4: Check whitespace**

Run: `git diff --check`

- [ ] **Step 5: Build one debug APK**

Run: `flutter build apk --debug`

If Windows path length blocks Flutter tooling, use the already established
short-path Gradle workaround without persisting any temporary Gradle change.
Verify APK existence, byte size and SHA-256. Do not create a commit.
