# ConsumoPlus Utility UX Harmonization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not use subagents and do not create commits before manual APK validation.

**Goal:** Make Water and Electricity feel like one responsive, accessible application through shared presentation primitives while preserving every provider and persistence behavior.

**Architecture:** Extend the existing contextual utility theme and replace only duplicated presentation widgets. Provider screens map their immutable records into shared display objects; sorting, statistics, masking, and chart layout remain in presentation and never modify persisted data.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, Material 3, CustomPaint, flutter_test.

## Global Constraints

- Preserve “Hogar claro”, Water blue, Electricity amber, and neutral ivory/light surfaces.
- Do not modify scraping, parsers, HTTP contracts, authentication, cookies, repositories, SQLCipher, schemas, migrations, credential storage, or local-first behavior.
- Do not add packages, predictions, notifications, backend, Firebase, or business features.
- Use only fictitious test data; never add real names, addresses, identifiers, HTML, cookies, or credentials.
- Do not redesign Home, create commits, merge, push, or generate intermediate APKs.
- Run focused tests during TDD and the complete verification sequence once at the end.

---

### Task 1: Legible shared chart and descriptive statistics

**Files:**
- Modify: `lib/shared/widgets/utility_consumption_chart.dart`
- Create: `lib/shared/widgets/utility_consumption_statistics.dart`
- Modify: `test/shared/widgets/utility_consumption_chart_test.dart`
- Create: `test/shared/widgets/utility_consumption_statistics_test.dart`

**Interfaces:**
- Extend `UtilityConsumptionPoint` with `String? contextualValue`.
- Extend `UtilityConsumptionChart` with `int maxPeriods` and optional `ValueChanged<UtilityConsumptionPoint>? onPointSelected` for test observability; internal tap behavior remains available when the callback is absent.
- Produce `UtilityConsumptionStatistics({required List<UtilityConsumptionPoint> points, required int maximumAveragePeriods, required String Function(double) valueFormatter})`.
- Keep `UtilityConsumptionChartPainter` public for focused painter assertions.

- [ ] **Step 1: Write failing chart behavior tests**

  Add tests that construct thirteen reversed fictitious points and assert:

  ```dart
  expect(painter.points, hasLength(6));
  expect(find.byKey(const Key('chartXAxis-Jun-2025')), findsOneWidget);
  expect(find.byKey(const Key('chartYAxis-0')), findsOneWidget);
  expect(find.byKey(const Key('chartLatestPoint')), findsOneWidget);
  expect(semanticsLabel, contains('Jun 2025: 2 metros cúbicos'));
  expect(semanticsLabel, isNot(contains('S/')));
  ```

  Add a twelve-period case that verifies every point reaches the painter while compact X labels may be skipped.

- [ ] **Step 2: Run the chart tests and confirm the current API/layout fails**

  Run:

  ```powershell
  flutter test test/shared/widgets/utility_consumption_chart_test.dart
  ```

  Expected: failure because `maxPeriods`, Y labels, latest-point key, and compact axis layout do not yet exist.

- [ ] **Step 3: Implement the chart scale and axes**

  Sort a defensive copy by `(year, month)`, retain the latest `maxPeriods`, and calculate a bounded scale:

  ```dart
  final rawRange = maximum - minimum;
  final minimumSpan = math.max(maximum.abs() * 0.20, 1.0);
  final span = math.max(rawRange * 1.35, minimumSpan);
  final lower = math.max(0.0, minimum - (span - rawRange) / 2);
  final upper = lower + span;
  ```

  Render four token-colored horizontal guides, readable Y labels outside the painter, Spanish abbreviated X labels, all visible data points, and a stronger latest point. Never render the old period/value `Wrap`.

- [ ] **Step 4: Implement point selection without a dependency**

  Convert the chart to a small stateful widget. Use `LayoutBuilder` plus `GestureDetector.onTapDown` to select the nearest visible point by X coordinate. Show one compact positioned tooltip containing:

  ```dart
  '${point.periodLabel}\n${point.displayValue}'
  // Append point.contextualValue only when non-null.
  ```

  Announce selection through a live-region semantic label. Do not draw a monetary series.

- [ ] **Step 5: Write and run failing statistics tests**

  Test seven points so the average uses only the latest six while maximum and minimum use the displayed range:

  ```dart
  expect(find.text('Promedio 6 meses'), findsOneWidget);
  expect(find.text('45 kWh'), findsOneWidget);
  expect(find.text('Mayor consumo'), findsOneWidget);
  expect(find.textContaining('70 kWh'), findsOneWidget);
  expect(find.text('Menor consumo'), findsOneWidget);
  expect(find.textContaining('10 kWh'), findsOneWidget);
  ```

  Run:

  ```powershell
  flutter test test/shared/widgets/utility_consumption_statistics_test.dart
  ```

- [ ] **Step 6: Implement statistics and rerun focused tests**

  Compute from a chronological defensive copy, format through the injected callback, and use three compact flexible metric cells. Run both shared widget test files and expect PASS.

---

### Task 2: Six-period summaries and twelve-period detailed Electricity chart

**Files:**
- Modify: `lib/features/water/presentation/widgets/consumption_chart.dart`
- Modify: `lib/features/electricity/presentation/widgets/electricity_consumption_chart.dart`
- Modify: `lib/features/water/presentation/widgets/water_summary.dart`
- Modify: `lib/features/electricity/presentation/widgets/electricity_summary.dart`
- Modify: `lib/features/electricity/presentation/electricity_consumption_screen.dart`
- Modify: `test/features/water/presentation/water_summary_test.dart`
- Modify: `test/features/electricity/presentation/electricity_screen_test.dart`
- Modify: `test/features/electricity/presentation/electricity_consumption_chart_test.dart`

**Interfaces:**
- `ConsumptionChart({required records, required int maxPeriods})` maps Water bill amount to `contextualValue`.
- `ElectricityConsumptionChart({required records, required int maxPeriods})` maps monthly charge to `contextualValue`.
- Provider summaries continue accepting their existing snapshots and callbacks.

- [ ] **Step 1: Add failing integration tests for 6/12 behavior**

  Build snapshots with thirteen fictitious periods. Assert Water and Electricity summaries expose only the latest six periods semantically and Electricity detail exposes the latest twelve in oldest-to-newest order:

  ```dart
  expect(summaryLabel, contains('Dic 2025'));
  expect(summaryLabel, isNot(contains('Nov 2025')));
  expect(detailPainter.points, hasLength(12));
  expect(detailLabel.indexOf('Sep 2025'), lessThan(detailLabel.indexOf('Ago 2026')));
  ```

- [ ] **Step 2: Run the three focused presentation test files**

  Expected: summary/detail counts fail because wrappers do not accept a maximum and Electricity summary has no graph.

- [ ] **Step 3: Map provider records into the shared chart**

  Pass `maxPeriods: 6` from both summaries and `maxPeriods: 12` from Electricity detail. Format tooltip money with existing `WaterFormatters.money` and `ElectricityFormatters.money`. Keep consumption as the only plotted numeric value.

- [ ] **Step 4: Add statistics at the approved locations**

  Place `UtilityConsumptionStatistics` under Water’s six-period chart and under Electricity’s detailed chart. Feed the exact points used by each visible chart; average at most six. Keep the Electricity main summary concise.

- [ ] **Step 5: Rerun the focused tests**

  Run the three files from Step 2 and expect PASS with no overflow or duplicate money series.

---

### Task 3: Shared history cards and deterministic newest-first lists

**Files:**
- Create: `lib/shared/widgets/history_record_card.dart`
- Modify: `lib/features/water/presentation/billing_history_screen.dart`
- Modify: `lib/features/water/presentation/payment_history_screen.dart`
- Modify: `lib/features/electricity/presentation/electricity_payment_screen.dart`
- Modify: `lib/features/electricity/presentation/electricity_consumption_screen.dart`
- Create: `test/shared/widgets/history_record_card_test.dart`
- Create: `test/features/water/presentation/water_history_screens_test.dart`
- Modify: `test/features/electricity/presentation/electricity_consumption_chart_test.dart`

**Interfaces:**
- Produce `HistoryRecordCard({required UtilityType utilityType, required String title, required String amount, required List<String> details, String? overline, IconData? icon, VoidCallback? onTap, List<Widget> expandedDetails = const []})`.
- The widget renders a compact `Card`; non-empty `expandedDetails` use an `ExpansionTile`, otherwise an `InkWell`/static row.

- [ ] **Step 1: Add failing shared-card tests**

  Verify title/amount can wrap at 320 px, the utility icon uses blue/amber, tap fires once, and expansion exposes tertiary details without changing the compact header.

- [ ] **Step 2: Run the shared-card test and confirm the class is absent**

  ```powershell
  flutter test test/shared/widgets/history_record_card_test.dart
  ```

- [ ] **Step 3: Implement the minimal reusable card**

  Use tokenized padding/radius, neutral `AppColors.surface`, an outline border, flexible title/amount columns, and `Semantics(container: true)`. Do not hardcode provider strings.

- [ ] **Step 4: Add failing ordering/mapping tests for all histories**

  Supply deliberately reversed fictitious records and assert the screen positions:

  ```dart
  expect(tester.getTopLeft(newest).dy, lessThan(tester.getTopLeft(oldest).dy));
  expect(find.byType(HistoryRecordCard), findsNWidgets(expectedCount));
  ```

  Verify Water bill tap still opens `BillingDetailScreen` and Water payment expansion still shows center, type, and detail.

- [ ] **Step 5: Replace flat rows and sort defensive copies**

  Sort Water bills by year/month descending, Water payments by date descending, Electricity payments by date descending, and Electricity consumptions by year/month descending. Map only existing values into `HistoryRecordCard`.

- [ ] **Step 6: Run Water and Electricity history tests**

  Expect PASS and verify no production model or stored collection is mutated.

---

### Task 4: Compact information sections, masking, and safe bottom actions

**Files:**
- Create: `lib/shared/widgets/info_section_card.dart`
- Modify: `lib/features/water/presentation/billing_detail_screen.dart`
- Modify: `lib/features/electricity/presentation/electricity_account_status_screen.dart`
- Modify: `lib/features/water/presentation/supply_details_screen.dart`
- Modify: `lib/features/electricity/presentation/electricity_supply_screen.dart`
- Create: `test/shared/widgets/info_section_card_test.dart`
- Create: `test/features/water/presentation/water_detail_screens_test.dart`
- Modify: `test/features/electricity/presentation/electricity_screen_test.dart`

**Interfaces:**
- Produce immutable `InfoRowData({required String label, required String value})`.
- Produce `InfoSectionCard({String? title, required List<InfoRowData> rows, UtilityType? utilityType})`.
- Produce a shared presentation helper `maskUtilityIdentifier(String value)` in the same file or a focused `masked_identifier.dart` if reuse makes the section file unclear.

- [ ] **Step 1: Write failing compact-section tests**

  Verify a titled section renders all pairs, uses one neutral card, preserves long values at 320 px/1.8× text, and displays the configured utility accent only in the section title/icon.

- [ ] **Step 2: Run the shared section test and confirm failure**

  ```powershell
  flutter test test/shared/widgets/info_section_card_test.dart
  ```

- [ ] **Step 3: Implement `InfoSectionCard` and `InfoRowData`**

  Use a compact label/value row that switches to a vertical arrangement when width or text scale cannot safely fit. Keep value selection enabled only if already supported; add no copy/share actions.

- [ ] **Step 4: Add failing screen tests**

  Assert Water bill detail has “Resumen” and “Facturación”; Electricity account status has “Resumen económico” and “Fechas”; both supply screens use the shared section. Assert:

  ```dart
  expect(find.text('CONTRATO-FICTICIO-001'), findsNothing);
  expect(find.textContaining('001'), findsWidgets);
  expect(find.text('MEDIDOR-FICTICIO-01'), findsNothing);
  expect(find.byKey(const Key('supplyBottomSafeArea')), findsOneWidget);
  ```

- [ ] **Step 5: Integrate details and masking**

  Group only the fields listed in the design. Mask Water customer code/meter and Electricity contract/meter through the same presentation helper. Leave owner/address and all stored model fields unchanged.

- [ ] **Step 6: Add safe bottom padding**

  Wrap each scrollable detail/supply body in `SafeArea(top: false)` and add tokenized bottom content padding. Keep action keys and existing confirmed callbacks unchanged.

- [ ] **Step 7: Rerun focused detail and supply tests**

  Expect PASS, including change/delete confirmation and the existing cross-utility deletion-isolation test.

---

### Task 5: Shared greeting, data access tiles, and contextual surfaces

**Files:**
- Create: `lib/shared/widgets/utility_greeting.dart`
- Create: `lib/shared/widgets/utility_access_tile.dart`
- Modify: `lib/features/water/presentation/widgets/water_summary.dart`
- Modify: `lib/features/electricity/presentation/widgets/electricity_summary.dart`
- Modify: `lib/app/theme/utility_theme.dart`
- Create: `test/shared/widgets/utility_greeting_test.dart`
- Create: `test/shared/widgets/utility_access_tile_test.dart`
- Modify: `test/app/theme/utility_theme_test.dart`
- Modify: Water/Electricity summary tests

**Interfaces:**
- Produce `UtilityGreeting({required String ownerName})`.
- Produce `UtilityAccessTile({required UtilityType utilityType, required IconData icon, required String title, String? subtitle, required VoidCallback onTap})`.

- [ ] **Step 1: Add failing long-name and access-tile tests**

  Use a fully fictitious long owner name at 320 px and 1.8×, assert `Hola,` plus the unmodified full value appears with no exception. Assert Water and Electricity access tiles share the same widget/radius/surface and expose blue/amber icon colors.

- [ ] **Step 2: Run the focused shared widget tests**

  Expected: failure because the shared classes do not exist.

- [ ] **Step 3: Implement the two shared widgets**

  Use no fixed height. `UtilityGreeting` renders the salutation and full name as separate text nodes. `UtilityAccessTile` uses a neutral card and contextual icon container.

- [ ] **Step 4: Replace duplicate summary UI**

  Add the shared “Explora tus datos” heading to Water and map its three actions. Map Electricity’s four actions. Preserve existing route callbacks and keys.

- [ ] **Step 5: Complete contextual Material controls**

  Extend `UtilityTheme` only where tests demonstrate inherited global blue, covering checkbox, input focus, and progress indicators through theme data. Do not hardcode amber in individual controls.

- [ ] **Step 6: Rerun theme and summary tests**

  Expect PASS with identical hierarchy and utility-specific accents.

---

### Task 6: Responsive/accessibility regression coverage and localized copy check

**Files:**
- Modify: `test/accessibility/responsive_layout_test.dart`
- Modify: affected presentation tests only when required by corrected widget structure
- Modify: visible copy files only if a concrete accent/capitalization defect remains
- Modify: `lib/features/settings/settings_screen.dart` only if its privacy description is still incomplete

**Interfaces:**
- No new production interface. This task validates the composition produced by Tasks 1–5.

- [ ] **Step 1: Add failing 320 px and text-scale scenarios**

  Pump representative Water summary, Electricity summary/detail, both supply screens, and the shared chart at 320×640 with 1.3× and 1.8× text. Scroll final actions into view and assert `tester.takeException()` is null.

- [ ] **Step 2: Add accessibility assertions**

  Verify chart semantic descriptions include every visible period/value, status banners remain live regions, access actions have meaningful labels, and masked identifiers—not full identifiers—are announced.

- [ ] **Step 3: Run focused responsive tests and fix only demonstrated layout defects**

  ```powershell
  flutter test test/accessibility/responsive_layout_test.dart
  ```

  Use flexible layout, wrapping, compact axis labels, or tokenized padding. Do not shrink text below the app typography system or introduce fixed card heights.

- [ ] **Step 4: Check visible copy and Settings**

  Search current production UI for broken capitalization/accents and verify Settings says queried data is stored encrypted on the device. Do not rewrite historical plans/specifications or add an appearance selector.

- [ ] **Step 5: Run all presentation-focused tests together**

  ```powershell
  flutter test test/shared test/features/water/presentation test/features/electricity/presentation test/accessibility
  ```

  Expected: PASS with no network access and only fictitious data.

---

### Task 7: Final verification and one debug APK

**Files:** No planned source changes; only corrections directly demonstrated by verification.

- [ ] **Step 1: Review scope and sensitive/generated files**

  Run read-only checks:

  ```powershell
  git status --short
  git diff --stat
  git diff --check
  ```

  Confirm no parser, remote data source, database schema, migration, real data, database, APK, `local.properties`, or temporary file is staged/tracked by this work.

- [ ] **Step 2: Format once**

  ```powershell
  dart format .
  ```

- [ ] **Step 3: Analyze once**

  ```powershell
  flutter analyze
  ```

  Expected: no issues.

- [ ] **Step 4: Run the complete test suite once**

  ```powershell
  flutter test
  ```

  Record the final passed test count.

- [ ] **Step 5: Check the final diff**

  ```powershell
  git diff --check
  ```

  Expected: no whitespace errors.

- [ ] **Step 6: Build exactly one debug APK**

  ```powershell
  flutter build apk --debug
  ```

  Confirm `build/app/outputs/flutter-apk/app-debug.apk` exists, record its absolute path and size, and leave every change uncommitted.
