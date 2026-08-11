export 'month_period.dart';

import 'month_period.dart';

class TimeSeriesPoint {
  const TimeSeriesPoint({required this.period, required this.value});

  final MonthPeriod period;
  final double value;
}

enum ForecastModelType {
  naive,
  simpleMovingAverage,
  weightedMovingAverage,
  linearRegression,
}

class SeriesForecast {
  SeriesForecast({
    required this.predictedPeriod,
    required this.central,
    required this.lower,
    required this.upper,
    required this.mae,
    required this.model,
    required this.variationPercent,
    required this.isHighlyVariable,
    required List<MonthPeriod> evaluationPeriods,
  }) : evaluationPeriods = List.unmodifiable(evaluationPeriods);

  final MonthPeriod predictedPeriod;
  final double central;
  final double lower;
  final double upper;
  final double mae;
  final ForecastModelType model;
  final double? variationPercent;
  final bool isHighlyVariable;
  final List<MonthPeriod> evaluationPeriods;

  int get evaluationCount => evaluationPeriods.length;
}
