import 'package:consumo_plus/features/home/domain/forecast/forecast_models.dart';
import 'package:consumo_plus/features/home/domain/forecast/forecasting_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthPeriod', () {
    test('advances from December to January using calendar months', () {
      expect(const MonthPeriod(2026, 12).next, const MonthPeriod(2027, 1));
    });

    test('measures real distance across year boundaries', () {
      expect(
        const MonthPeriod(2026, 11).monthsUntil(const MonthPeriod(2027, 2)),
        3,
      );
    });

    test('rejects months outside the calendar range', () {
      expect(() => MonthPeriod(2026, 0), throwsA(isA<AssertionError>()));
      expect(() => MonthPeriod(2026, 13), throwsA(isA<AssertionError>()));
    });
  });

  group('forecasting models', () {
    test('Naive projects the last real value one month ahead', () {
      expect(
        const NaiveForecastingModel().predict(
          _points([10, 20, 30]),
          const MonthPeriod(2026, 4),
        ),
        30,
      );
    });

    test('simple moving average uses the last three real values', () {
      expect(
        const SimpleMovingAverageForecastingModel().predict(
          _points([10, 20, 40]),
          const MonthPeriod(2026, 4),
        ),
        closeTo(70 / 3, 1e-9),
      );
    });

    test('weighted moving average assigns weights one, two and three', () {
      expect(
        const WeightedMovingAverageForecastingModel().predict(
          _points([10, 20, 40]),
          const MonthPeriod(2026, 4),
        ),
        closeTo(170 / 6, 1e-9),
      );
    });

    test('linear regression projects an increasing series one month', () {
      expect(
        const LinearRegressionForecastingModel().predict(
          _points([10, 20, 30]),
          const MonthPeriod(2026, 4),
        ),
        closeTo(40, 1e-9),
      );
    });

    test('linear regression keeps a constant series constant', () {
      expect(
        const LinearRegressionForecastingModel().predict(
          _points([25, 25, 25, 25]),
          const MonthPeriod(2026, 5),
        ),
        closeTo(25, 1e-9),
      );
    });

    test('linear regression respects missing-month distance', () {
      final points = [
        const TimeSeriesPoint(period: MonthPeriod(2026, 1), value: 10),
        const TimeSeriesPoint(period: MonthPeriod(2026, 3), value: 30),
        const TimeSeriesPoint(period: MonthPeriod(2026, 4), value: 40),
      ];

      expect(
        const LinearRegressionForecastingModel().predict(
          points,
          const MonthPeriod(2026, 5),
        ),
        closeTo(50, 1e-9),
      );
    });

    test('moving models reject a non-consecutive three-month window', () {
      final points = [
        const TimeSeriesPoint(period: MonthPeriod(2026, 1), value: 10),
        const TimeSeriesPoint(period: MonthPeriod(2026, 3), value: 30),
        const TimeSeriesPoint(period: MonthPeriod(2026, 4), value: 40),
      ];

      expect(
        const SimpleMovingAverageForecastingModel().canPredict(
          points,
          const MonthPeriod(2026, 5),
        ),
        isFalse,
      );
      expect(
        const WeightedMovingAverageForecastingModel().canPredict(
          points,
          const MonthPeriod(2026, 5),
        ),
        isFalse,
      );
    });

    test('every model refuses to skip beyond the next period', () {
      for (final model in forecastingModels) {
        expect(
          model.canPredict(_points([10, 20, 30]), const MonthPeriod(2026, 5)),
          isFalse,
          reason: model.type.name,
        );
      }
    });

    test('regression clamps a negative physical projection to zero', () {
      expect(
        const LinearRegressionForecastingModel().predict(
          _points([30, 15, 0]),
          const MonthPeriod(2026, 4),
        ),
        0,
      );
    });
  });
}

List<TimeSeriesPoint> _points(List<num> values) => [
  for (var index = 0; index < values.length; index++)
    TimeSeriesPoint(
      period: MonthPeriod(2026, index + 1),
      value: values[index].toDouble(),
    ),
];
