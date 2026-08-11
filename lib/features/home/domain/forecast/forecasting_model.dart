import 'dart:math' as math;

import 'forecast_models.dart';

class ForecastUnavailableException implements Exception {
  const ForecastUnavailableException();
}

abstract interface class ForecastingModel {
  ForecastModelType get type;

  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target);

  double predict(List<TimeSeriesPoint> training, MonthPeriod target);
}

const forecastingModels = <ForecastingModel>[
  NaiveForecastingModel(),
  SimpleMovingAverageForecastingModel(),
  WeightedMovingAverageForecastingModel(),
  LinearRegressionForecastingModel(),
];

class NaiveForecastingModel implements ForecastingModel {
  const NaiveForecastingModel();

  @override
  ForecastModelType get type => ForecastModelType.naive;

  @override
  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target) =>
      _validTraining(training, minimumPoints: 1) &&
      training.last.period.isImmediatelyBefore(target);

  @override
  double predict(List<TimeSeriesPoint> training, MonthPeriod target) {
    _requirePrediction(this, training, target);
    return _nonNegative(training.last.value);
  }
}

class SimpleMovingAverageForecastingModel implements ForecastingModel {
  const SimpleMovingAverageForecastingModel();

  @override
  ForecastModelType get type => ForecastModelType.simpleMovingAverage;

  @override
  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target) =>
      _hasConsecutiveTail(training, target);

  @override
  double predict(List<TimeSeriesPoint> training, MonthPeriod target) {
    _requirePrediction(this, training, target);
    final tail = training.sublist(training.length - 3);
    final total = tail.fold<double>(0, (sum, point) => sum + point.value);
    return _nonNegative(total / 3);
  }
}

class WeightedMovingAverageForecastingModel implements ForecastingModel {
  const WeightedMovingAverageForecastingModel();

  @override
  ForecastModelType get type => ForecastModelType.weightedMovingAverage;

  @override
  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target) =>
      _hasConsecutiveTail(training, target);

  @override
  double predict(List<TimeSeriesPoint> training, MonthPeriod target) {
    _requirePrediction(this, training, target);
    final tail = training.sublist(training.length - 3);
    return _nonNegative(
      (tail[0].value + 2 * tail[1].value + 3 * tail[2].value) / 6,
    );
  }
}

class LinearRegressionForecastingModel implements ForecastingModel {
  const LinearRegressionForecastingModel();

  @override
  ForecastModelType get type => ForecastModelType.linearRegression;

  @override
  bool canPredict(List<TimeSeriesPoint> training, MonthPeriod target) =>
      _validTraining(training, minimumPoints: 2) &&
      training.last.period.isImmediatelyBefore(target);

  @override
  double predict(List<TimeSeriesPoint> training, MonthPeriod target) {
    _requirePrediction(this, training, target);
    final origin = training.first.period.ordinal;
    final count = training.length.toDouble();
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXX = 0.0;
    var sumXY = 0.0;
    for (final point in training) {
      final x = (point.period.ordinal - origin).toDouble();
      sumX += x;
      sumY += point.value;
      sumXX += x * x;
      sumXY += x * point.value;
    }
    final denominator = count * sumXX - sumX * sumX;
    if (denominator == 0) throw const ForecastUnavailableException();
    final slope = (count * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / count;
    final targetX = (target.ordinal - origin).toDouble();
    return _nonNegative(intercept + slope * targetX);
  }
}

bool _validTraining(
  List<TimeSeriesPoint> training, {
  required int minimumPoints,
}) {
  if (training.length < minimumPoints) return false;
  for (var index = 0; index < training.length; index++) {
    final point = training[index];
    if (!point.value.isFinite || point.value < 0) return false;
    if (index > 0 && training[index - 1].period.compareTo(point.period) >= 0) {
      return false;
    }
  }
  return true;
}

bool _hasConsecutiveTail(List<TimeSeriesPoint> training, MonthPeriod target) {
  if (!_validTraining(training, minimumPoints: 3)) return false;
  final first = training[training.length - 3].period;
  final second = training[training.length - 2].period;
  final third = training.last.period;
  return first.isImmediatelyBefore(second) &&
      second.isImmediatelyBefore(third) &&
      third.isImmediatelyBefore(target);
}

void _requirePrediction(
  ForecastingModel model,
  List<TimeSeriesPoint> training,
  MonthPeriod target,
) {
  if (!model.canPredict(training, target)) {
    throw const ForecastUnavailableException();
  }
}

double _nonNegative(double value) => math.max(0, value).toDouble();
