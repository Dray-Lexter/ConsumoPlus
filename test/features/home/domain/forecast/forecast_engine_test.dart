import 'dart:math' as math;

import 'package:consumo_plus/features/home/domain/forecast/forecast_engine.dart';
import 'package:consumo_plus/features/home/domain/forecast/forecast_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MAE averages hand-calculated absolute errors', () {
    expect(meanAbsoluteError([2, 4, 6]), 4);
  });

  test('twelve consecutive months use the same nine evaluation targets', () {
    final result = const ForecastEngine().forecast(
      _points([10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]),
    );

    expect(result, isNotNull);
    expect(result!.evaluationCount, 9);
    expect(result.evaluationPeriods, [
      for (var month = 4; month <= 12; month++) MonthPeriod(2026, month),
    ]);
    expect(result.model, ForecastModelType.linearRegression);
    expect(result.predictedPeriod, const MonthPeriod(2027, 1));
    expect(result.central, closeTo(130, 1e-9));
  });

  test('six consecutive months provide exactly three common evaluations', () {
    final result = const ForecastEngine().forecast(
      _points([10, 11, 12, 13, 14, 15]),
    );

    expect(result, isNotNull);
    expect(result!.evaluationCount, 3);
    expect(result.evaluationPeriods, const [
      MonthPeriod(2026, 4),
      MonthPeriod(2026, 5),
      MonthPeriod(2026, 6),
    ]);
  });

  test(
    'a constant series deterministically selects the simpler Naive model',
    () {
      final result = const ForecastEngine().forecast(
        _points([25, 25, 25, 25, 25, 25]),
      );

      expect(result?.model, ForecastModelType.naive);
      expect(result?.mae, 0);
      expect(result?.central, 25);
    },
  );

  test('one-percent equivalent MAE prefers the simpler model', () {
    final selected = selectBestModel({
      ForecastModelType.naive: 10.05,
      ForecastModelType.simpleMovingAverage: 10,
      ForecastModelType.weightedMovingAverage: 14,
      ForecastModelType.linearRegression: 18,
    });

    expect(selected, ForecastModelType.naive);
  });

  test('MAE range is centered on the selected projection', () {
    final result = const ForecastEngine().forecast(
      _points([12, 20, 18, 25, 19, 28, 24]),
    );

    expect(result, isNotNull);
    expect(result!.lower, math.max(0, result.central - result.mae));
    expect(result.upper, result.central + result.mae);
  });

  test('range lower bound never becomes negative', () {
    final result = const ForecastEngine().forecast(
      _points([0, 100, 0, 100, 0, 100]),
    );

    expect(result, isNotNull);
    expect(result!.lower, greaterThanOrEqualTo(0));
  });

  test('zero latest value omits percentage variation', () {
    final result = const ForecastEngine().forecast(_points([0, 0, 0, 0, 0, 0]));

    expect(result?.variationPercent, isNull);
  });

  test('fewer than three common origins rejects an irregular history', () {
    final result = const ForecastEngine().forecast([
      _point(2026, 1, 10),
      _point(2026, 2, 20),
      _point(2026, 3, 30),
      _point(2026, 4, 40),
      _point(2026, 6, 60),
      _point(2026, 7, 70),
    ]);

    expect(result, isNull);
  });

  test(
    'the selected regression can project across an earlier calendar gap',
    () {
      final result = const ForecastEngine().forecast([
        ..._points([10, 20, 30, 40, 50, 60]),
        _point(2026, 8, 80),
      ]);

      expect(result, isNotNull);
      expect(result!.model, ForecastModelType.linearRegression);
      expect(result.predictedPeriod, const MonthPeriod(2026, 9));
      expect(result.central, closeTo(90, 1e-9));
    },
  );

  test('high retrospective error marks a history as highly variable', () {
    final result = const ForecastEngine().forecast(
      _points([0, 100, 0, 100, 0, 100]),
    );

    expect(result?.isHighlyVariable, isTrue);
  });

  test('negative and non-finite observations are rejected', () {
    expect(
      const ForecastEngine().forecast(_points([1, 2, 3, 4, 5, -1])),
      isNull,
    );
    expect(
      const ForecastEngine().forecast(_points([1, 2, 3, 4, 5, double.nan])),
      isNull,
    );
  });
}

List<TimeSeriesPoint> _points(List<num> values) => [
  for (var index = 0; index < values.length; index++)
    _point(2026, index + 1, values[index].toDouble()),
];

TimeSeriesPoint _point(int year, int month, double value) =>
    TimeSeriesPoint(period: MonthPeriod(year, month), value: value);
