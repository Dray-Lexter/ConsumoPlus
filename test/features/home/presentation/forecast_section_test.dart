import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/domain/forecast/forecast_models.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:consumo_plus/features/home/presentation/widgets/forecast_section.dart';
import 'package:consumo_plus/features/home/presentation/widgets/service_forecast_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject(
  List<ServiceForecast> forecasts, {
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ForecastSection(forecasts: forecasts),
      ),
    ),
  ),
);

ServiceForecast _estimate({
  required UtilityType utilityType,
  ForecastStatus status = ForecastStatus.sufficient,
  TrendClassification trend = TrendClassification.stable,
  double consumptionVariation = 3,
  double costVariation = 4,
  int sampleCount = 12,
  bool highlyVariable = false,
}) {
  final water = utilityType == UtilityType.water;
  return ServiceForecast(
    utilityType: utilityType,
    serviceName: water ? 'Agua' : 'Electricidad',
    providerName: water ? 'EPS Tacna' : 'Electrosur',
    consumptionUnit: water ? 'm³' : 'kWh',
    sampleCount: sampleCount,
    status: status,
    insufficientReason: null,
    predictedPeriod: const MonthPeriod(2026, 9),
    consumption: SeriesForecast(
      predictedPeriod: const MonthPeriod(2026, 9),
      central: water ? 14 : 352,
      lower: water ? 12.5 : 338,
      upper: water ? 15.5 : 366,
      mae: water ? 1.5 : 14,
      model: ForecastModelType.weightedMovingAverage,
      variationPercent: consumptionVariation,
      isHighlyVariable: highlyVariable,
      evaluationPeriods: const [MonthPeriod(2026, 8)],
    ),
    cost: SeriesForecast(
      predictedPeriod: const MonthPeriod(2026, 9),
      central: 34000,
      lower: 32400,
      upper: 35600,
      mae: 1600,
      model: ForecastModelType.linearRegression,
      variationPercent: costVariation,
      isHighlyVariable: false,
      evaluationPeriods: const [MonthPeriod(2026, 8)],
    ),
    trend: trend,
  );
}

ServiceForecast _insufficient(
  UtilityType utilityType, {
  ForecastInsufficientReason reason =
      ForecastInsufficientReason.notEnoughHistory,
}) {
  final water = utilityType == UtilityType.water;
  return ServiceForecast(
    utilityType: utilityType,
    serviceName: water ? 'Agua' : 'Electricidad',
    providerName: water ? 'EPS Tacna' : 'Electrosur',
    consumptionUnit: water ? 'm³' : 'kWh',
    sampleCount: 5,
    status: ForecastStatus.insufficient,
    insufficientReason: reason,
    predictedPeriod: null,
    consumption: null,
    cost: null,
    trend: null,
  );
}

void main() {
  testWidgets('renders nothing without a connected active service', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(const []));

    expect(find.text('Tu consumo estimado'), findsNothing);
    expect(find.byType(ServiceForecastCard), findsNothing);
  });

  testWidgets('renders only Water with m³ and independently estimated money', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject([_estimate(utilityType: UtilityType.water)]),
    );

    expect(find.text('Tu consumo estimado'), findsOneWidget);
    expect(find.byKey(const Key('forecastCard-water')), findsOneWidget);
    expect(find.text('EPS Tacna'), findsOneWidget);
    expect(find.text('12,5–15,5 m³'), findsOneWidget);
    expect(find.text('S/ 324.00–356.00'), findsOneWidget);
    expect(find.text('Electrosur'), findsNothing);
  });

  testWidgets('renders only Electricity with kWh and the predicted period', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject([_estimate(utilityType: UtilityType.electricity)]),
    );

    expect(find.byKey(const Key('forecastCard-electricity')), findsOneWidget);
    expect(find.text('Electrosur'), findsOneWidget);
    expect(find.text('338–366 kWh'), findsOneWidget);
    expect(find.text('Estimación para septiembre de 2026'), findsOneWidget);
    expect(find.text('EPS Tacna'), findsNothing);
  });

  testWidgets('renders both connected services with shared cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject([
        _estimate(utilityType: UtilityType.water),
        _estimate(utilityType: UtilityType.electricity),
      ]),
    );

    expect(find.byType(ServiceForecastCard), findsNWidgets(2));
    expect(find.text('Consumo estimado'), findsNWidgets(2));
    expect(find.text('Pago estimado'), findsNWidgets(2));
  });

  testWidgets('shows the complete orientative disclaimer once', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _subject([
          _estimate(utilityType: UtilityType.water),
          _estimate(utilityType: UtilityType.electricity),
        ]),
      );

      const disclaimer =
          'Las estimaciones son orientativas y no garantizan el consumo ni el importe futuro.';
      expect(find.text(disclaimer), findsOneWidget);
      expect(find.bySemanticsLabel(disclaimer), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('explains insufficient and irregular histories without numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject([
        _insufficient(UtilityType.water),
        _insufficient(
          UtilityType.electricity,
          reason: ForecastInsufficientReason.irregular,
        ),
      ]),
    );

    expect(find.text('Historial insuficiente'), findsNWidgets(2));
    expect(find.text('Aún necesitamos más historial'), findsOneWidget);
    expect(
      find.text(
        'ConsumoPlus necesita al menos 6 meses para realizar una estimación.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Historial insuficiente o irregular para estimar'),
      findsOneWidget,
    );
    expect(find.text('Consumo estimado'), findsNothing);
    expect(find.textContaining('🙂'), findsNothing);
    expect(find.textContaining('🙁'), findsNothing);
  });

  testWidgets('shows preliminary, sufficient, and variability disclosures', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject([
        _estimate(
          utilityType: UtilityType.water,
          status: ForecastStatus.preliminary,
          sampleCount: 8,
        ),
        _estimate(utilityType: UtilityType.electricity, highlyVariable: true),
      ]),
    );

    expect(find.text('Estimación preliminar'), findsOneWidget);
    expect(find.text('Basado en 12 meses de historial'), findsOneWidget);
    expect(
      find.text(
        'Tu historial presenta bastante variación, por lo que el rango '
        'estimado es más amplio.',
      ),
      findsOneWidget,
    );
    expect(find.text('Estimación orientativa'), findsNWidgets(2));
  });

  testWidgets(
    'trend follows consumption while cost variation stays secondary',
    (tester) async {
      await tester.pumpWidget(
        _subject([
          _estimate(
            utilityType: UtilityType.electricity,
            trend: TrendClassification.favorable,
            consumptionVariation: -8,
            costVariation: 40,
          ),
        ]),
      );

      expect(find.text('🙂 Tendencia favorable'), findsOneWidget);
      expect(
        find.text('≈ 8 % menos de consumo que el último mes'),
        findsOneWidget,
      );
      expect(
        find.text('≈ 40 % más de importe que el último periodo'),
        findsOneWidget,
      );
      expect(find.text('🙁 Tendencia al alza'), findsNothing);
    },
  );

  testWidgets('card is announced as information and has no tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _subject([_estimate(utilityType: UtilityType.electricity)]),
      );

      final finder = find.bySemanticsLabel(
        RegExp('Electricidad, Electrosur.*Rango estimado de consumo'),
      );
      expect(finder, findsOneWidget);
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isButton, isFalse);
      expect(
        find.descendant(
          of: find.byKey(const Key('forecastCard-electricity')),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final scale in <double>[1.3, 1.8]) {
    testWidgets('fits 320 px with ${scale}x text and remains scrollable', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _subject([
          _estimate(utilityType: UtilityType.water),
          _estimate(utilityType: UtilityType.electricity),
        ], textScaler: TextScaler.linear(scale)),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('forecastCard-electricity')),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.byKey(const Key('forecastCard-electricity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
