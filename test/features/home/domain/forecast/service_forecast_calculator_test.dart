import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/domain/forecast/forecast_models.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ServiceForecastCalculator();

  test('fewer than six valid months exposes no numerical forecast', () {
    final result = calculator.build([_input(_observations(5))]).single;

    expect(result.status, ForecastStatus.insufficient);
    expect(
      result.insufficientReason,
      ForecastInsufficientReason.notEnoughHistory,
    );
    expect(result.consumption, isNull);
    expect(result.cost, isNull);
    expect(result.trend, isNull);
  });

  test('six to eleven months produce a preliminary forecast', () {
    for (final count in [6, 7, 11]) {
      final result = calculator.build([_input(_observations(count))]).single;

      expect(result.status, ForecastStatus.preliminary, reason: '$count');
      expect(result.sampleCount, count);
      expect(result.consumption, isNotNull);
      expect(result.cost, isNotNull);
    }
  });

  test('twelve months produce a sufficient forecast', () {
    final result = calculator.build([_input(_observations(12))]).single;

    expect(result.status, ForecastStatus.sufficient);
    expect(result.sampleCount, 12);
    expect(result.consumption?.evaluationCount, 9);
    expect(result.cost?.evaluationCount, 9);
  });

  test('more than twelve months retains only the latest twelve', () {
    final result = calculator.build([_input(_observations(14))]).single;

    expect(result.status, ForecastStatus.sufficient);
    expect(result.sampleCount, 12);
    expect(result.predictedPeriod, const MonthPeriod(2026, 3));
  });

  test('portal order does not change the result', () {
    final ordered = _observations(12);
    final reversed = ordered.reversed.toList();

    final first = calculator.build([_input(ordered)]).single;
    final second = calculator.build([_input(reversed)]).single;

    expect(second.predictedPeriod, first.predictedPeriod);
    expect(second.consumption?.central, first.consumption?.central);
    expect(second.cost?.central, first.cost?.central);
    expect(second.consumption?.model, first.consumption?.model);
  });

  test('same-period duplicates choose newest then lexical natural key', () {
    final base = _constantObservations(6, value: 25);
    final period = base[2].period;
    final sync = base[2].synchronizedAt;
    final result = calculator.build([
      _input([
        ...base,
        MonthlyUtilityObservation(
          period: period,
          consumption: 999,
          monthlyCostCents: 99900,
          synchronizedAt: sync,
          sourceKey: 'A-OLDER-TIE',
        ),
        MonthlyUtilityObservation(
          period: period,
          consumption: 25,
          monthlyCostCents: 2500,
          synchronizedAt: sync,
          sourceKey: 'Z-SELECTED-TIE',
        ),
      ]),
    ]).single;

    expect(result.sampleCount, 6);
    expect(result.consumption?.central, 25);
    expect(result.cost?.central, 2500);
  });

  test('invalid observations are removed instead of becoming zero months', () {
    final values = _observations(7);
    final invalid = values.last;
    values[6] = MonthlyUtilityObservation(
      period: invalid.period,
      consumption: -1,
      monthlyCostCents: invalid.monthlyCostCents,
      synchronizedAt: invalid.synchronizedAt,
      sourceKey: invalid.sourceKey,
    );

    final result = calculator.build([_input(values)]).single;

    expect(result.sampleCount, 6);
    expect(result.status, ForecastStatus.preliminary);
    expect(result.predictedPeriod, values[5].period.next);
  });

  test('irregular history without three comparable origins stays neutral', () {
    final result = calculator.build([
      _input([
        _observation(2026, 1, 10),
        _observation(2026, 2, 20),
        _observation(2026, 3, 30),
        _observation(2026, 4, 40),
        _observation(2026, 6, 60),
        _observation(2026, 7, 70),
      ]),
    ]).single;

    expect(result.status, ForecastStatus.insufficient);
    expect(result.insufficientReason, ForecastInsufficientReason.irregular);
    expect(result.trend, isNull);
  });

  test('December predicts January of the next year', () {
    final result = calculator.build([
      _input([
        for (var month = 7; month <= 12; month++)
          _observation(2026, month, month.toDouble()),
      ]),
    ]).single;

    expect(result.predictedPeriod, const MonthPeriod(2027, 1));
  });

  test('consumption and cost independently select different models', () {
    final observations = [
      for (var index = 0; index < 12; index++)
        MonthlyUtilityObservation(
          period: _periodAt(index),
          consumption: 10 + index * 10,
          monthlyCostCents: 5000,
          synchronizedAt: DateTime.utc(2026, 1, index + 1),
          sourceKey: 'R-$index',
        ),
    ];

    final result = calculator.build([_input(observations)]).single;

    expect(result.consumption?.model, ForecastModelType.linearRegression);
    expect(result.cost?.model, ForecastModelType.naive);
  });

  test('trend thresholds depend only on consumption variation', () {
    expect(classifyConsumptionTrend(-5), TrendClassification.favorable);
    expect(classifyConsumptionTrend(-4.999), TrendClassification.stable);
    expect(classifyConsumptionTrend(4.999), TrendClassification.stable);
    expect(classifyConsumptionTrend(5), TrendClassification.rising);
    expect(classifyConsumptionTrend(null), isNull);
  });

  test('zero latest consumption omits variation and trend', () {
    final result = calculator.build([
      _input(_constantObservations(6, value: 0)),
    ]).single;

    expect(result.consumption?.variationPercent, isNull);
    expect(result.trend, isNull);
  });
}

ServiceForecastInput _input(List<MonthlyUtilityObservation> observations) =>
    ServiceForecastInput(
      utilityType: UtilityType.water,
      serviceName: 'Agua',
      providerName: 'EPS Tacna',
      consumptionUnit: 'm³',
      observations: observations,
    );

List<MonthlyUtilityObservation> _observations(int count) => [
  for (var index = 0; index < count; index++)
    MonthlyUtilityObservation(
      period: _periodAt(index),
      consumption: 10 + index.toDouble(),
      monthlyCostCents: 3000 + index * 100,
      synchronizedAt: DateTime.utc(2026, 1, 1).add(Duration(days: index)),
      sourceKey: 'R-$index',
    ),
];

List<MonthlyUtilityObservation> _constantObservations(
  int count, {
  required double value,
}) => [
  for (var index = 0; index < count; index++)
    MonthlyUtilityObservation(
      period: _periodAt(index),
      consumption: value,
      monthlyCostCents: value * 100,
      synchronizedAt: DateTime.utc(2026, 1, 1).add(Duration(days: index)),
      sourceKey: 'R-$index',
    ),
];

MonthlyUtilityObservation _observation(int year, int month, double value) =>
    MonthlyUtilityObservation(
      period: MonthPeriod(year, month),
      consumption: value,
      monthlyCostCents: value * 100,
      synchronizedAt: DateTime.utc(year, month),
      sourceKey: '$year-$month',
    );

MonthPeriod _periodAt(int index) {
  final date = DateTime(2025, 1 + index);
  return MonthPeriod(date.year, date.month);
}
