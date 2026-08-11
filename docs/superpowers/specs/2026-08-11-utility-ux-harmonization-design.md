# ConsumoPlus Utility UX Harmonization Design

## Scope and invariants

Harmonize Water / EPS Tacna and Electricity / Electrosur without changing
scraping, parsers, HTTP contracts, authentication, cookies, repositories,
SQLCipher, database schemas, migrations, credential storage, or local-first
behavior. The direction remains **Hogar claro**: an ivory canvas, neutral light
surfaces, shared typography and spacing, blue Water identity, and amber
Electricity identity.

The work is presentation-only. No prediction, notifications, backend,
Firebase, provider selector, or business feature is added. Home keeps its
current composition. Settings remains informational.

## Shared visual system

- `UtilityTheme` derives the contextual Material `ColorScheme` from
  `UtilityType.visual`, covering primary controls, focused inputs, checkboxes,
  and progress indicators without recoloring the whole page.
- `UtilityGreeting` presents `Hola,` and the complete provider name in a
  two-line-tolerant layout. It never infers or alters a first name.
- `UtilityUpdateButton` supplies the same full-width primary action and busy
  state for both services.
- `UtilityAccessTile` supplies the same compact navigation pattern for
  “Explora tus datos”, using the service accent only on the icon/accent.
- `UtilityMessageBanner` provides information, success, warning, error, and
  accessible live-region behavior. Provider copy remains provider-specific.
- `HistoryRecordCard` provides one compact card language for bills, payments,
  and consumption rows while allowing an optional tap or expansion.
- `InfoSectionCard` and `InfoRow` group label/value pairs into compact mobile
  sections for bill details, account status, and supply data.
- `UtilitySensitiveActions` preserves the shared Change/Delete hierarchy and
  mandatory confirmations.

Shared widgets accept formatted strings and callbacks. They do not depend on
provider domain models or contain navigation, HTTP, SQL, or deletion logic.

## Summary composition

Both summaries follow the same vertical hierarchy:

1. `Servicio · Proveedor` app bar.
2. Robust greeting.
3. Last update.
4. New-month recommendation when applicable.
5. Full-width “Actualizar con mi clave” action.
6. Current period, current consumption, and variation.
7. Provider-specific economic summary.
8. Six-period consumption chart.
9. Local descriptive statistics where data exists.
10. “Explora tus datos” navigation.
11. Sensitive local-data action.

Water and Electricity keep distinct domain summaries because their available
financial fields differ. Layout rhythm, neutral surfaces, radii, spacing,
typography, and interaction patterns remain shared.

## Consumption chart

The existing shared name `UtilityConsumptionChart` is retained. Provider
wrappers map existing records into immutable `UtilityConsumptionPoint`
objects with year, month, consumption, formatted unit value, optional monetary
context, and semantic value.

The component accepts an explicit maximum period count:

- Water summary: latest 6 periods.
- Electricity summary: latest 6 periods.
- Electricity detailed consumption screen: latest 12 periods.

It always sorts the visible series chronologically from oldest to newest. The
chart shows abbreviated Spanish month labels, adding a compact year only when
needed to disambiguate years. With 12 periods it may omit alternating X-axis
labels, but it never removes data points.

The Y axis uses three or four human-readable references and soft horizontal
guides. Its scale is based on visible values with a proportional margin and a
minimum span, so the line uses the available height without exaggerating tiny
variations. The current period has a slightly stronger point and treatment.
There is no monetary series, second line, or second Y axis.

Touching or tapping near a point selects it and displays a compact tooltip
containing period, consumption, and optional bill amount. This interaction is
implemented with Flutter primitives and `CustomPaint`; no chart dependency is
added. The full visible series remains available through one semantic image
description containing period, consumption, and unit, so the graph is never
the only source of information.

## Descriptive statistics

`UtilityConsumptionStatistics` receives the already-visible local points and
computes only:

- average of the latest 6 periods;
- highest consumption in the displayed range;
- lowest consumption in the displayed range.

Water uses m³ and Electricity uses kWh. Missing or short histories produce
only values that can be calculated; no prediction or invented value is shown.
The statistics appear below the Water six-period chart and below the detailed
Electricity chart. The Electricity summary remains concise.

## Histories and details

All list histories are defensively sorted newest to oldest in presentation;
persisted order is not changed. `HistoryRecordCard` maps current fields with a
compact hierarchy:

- Water bills: period and total first; consumption and bill/debt secondary;
  receipt number tertiary; tap still opens bill detail.
- Water payments: amount, date/period, and payment center first; type and
  detail remain available through expansion.
- Electricity payments: amount, date, center, and period.
- Electricity consumptions: period and kWh first; tariff and amount secondary.

Bill detail uses “Resumen” and “Facturación” sections. Electricity account
status uses “Resumen económico” and “Fechas”. Supply screens use the same
label/value rhythm without wrapping every field in a separate card.

## Privacy, sensitive actions, and safe areas

Water continues to mask customer code and meter. Electricity masks contract
and meter by default using only a presentation transform; stored values are
unchanged. Owner and address remain visible and are never logged.

Both supply screens end with “Cambiar de suministro” and “Eliminar datos de
Servicio”. Change uses the contextual outline; Delete uses the soft error
treatment and always confirms. Existing module-scoped deletion flows remain
unchanged, so deleting one utility preserves the other and does not disturb
the shared encryption key.

Every scrollable detail or supply screen uses a bottom `SafeArea` and tokenized
padding so final actions can scroll fully above Android system navigation.

## Responsive and accessibility behavior

Cards avoid fixed content heights. Text and values may wrap without being
clipped at 320 px and text scales 1.3× or 1.8×. Chart labels adapt to width,
skip only redundant X labels, and retain every semantic data point. Interactive
targets keep meaningful labels, and state banners use live regions.

## Testing and verification

Focused widget tests cover:

- six-period summaries and twelve-period detailed chart;
- chronological graph order, abbreviated month labels, Y references,
  latest-point treatment, tooltip, unit, and semantics;
- descriptive average/minimum/maximum from local data;
- newest-first histories and shared record cards;
- compact information sections;
- Water and Electricity identifier masking;
- robust long names, bottom safe area, change/delete confirmation, and
  cross-utility isolation;
- blue/amber contextual controls;
- 320 px layouts and 1.3×/1.8× text scaling.

Fixtures and tests use only fictitious data. Final verification runs format,
`flutter analyze`, the complete test suite, `git diff --check`, and one debug
APK build. No commit, merge, or push is created before manual APK validation.
