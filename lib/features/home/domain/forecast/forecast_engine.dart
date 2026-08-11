import 'dart:math' as math;

import 'forecast_models.dart';
import 'forecasting_model.dart';

class ForecastEngine {
  const ForecastEngine({this.models = forecastingModels});

  final List<ForecastingModel> models;

  SeriesForecast? forecast(List<TimeSeriesPoint> points) {
    if (!_validSeries(points) || models.isEmpty) return null;
    final evaluationIndexes = <int>[];
    for (var index = 3; index < points.length; index++) {
      final training = points.sublist(0, index);
      final target = points[index].period;
      if (models.every((model) => model.canPredict(training, target))) {
        evaluationIndexes.add(index);
      }
    }
    if (evaluationIndexes.length < 3) return null;

    final scores = <ForecastModelType, double>{};
    for (final model in models) {
      final errors = <double>[];
      for (final index in evaluationIndexes) {
        final prediction = _nonNegative(
          model.predict(points.sublist(0, index), points[index].period),
        );
        errors.add((points[index].value - prediction).abs());
      }
      scores[model.type] = meanAbsoluteError(errors);
    }

    final selectedType = selectBestModel(scores);
    final selected = models.firstWhere((model) => model.type == selectedType);
    final predictedPeriod = points.last.period.next;
    if (!selected.canPredict(points, predictedPeriod)) {
      return null;
    }
    final central = _nonNegative(selected.predict(points, predictedPeriod));
    final mae = scores[selectedType]!;
    final last = points.last.value;
    final variation = last == 0 ? null : ((central - last) / last) * 100;
    final mean =
        points.fold<double>(0, (sum, point) => sum + point.value) /
        points.length;

    return SeriesForecast(
      predictedPeriod: predictedPeriod,
      central: central,
      lower: math.max(0, central - mae).toDouble(),
      upper: math.max(0, central + mae).toDouble(),
      mae: mae,
      model: selectedType,
      variationPercent: variation,
      isHighlyVariable: mean > 0 && mae / mean >= 0.25,
      evaluationPeriods: [
        for (final index in evaluationIndexes) points[index].period,
      ],
    );
  }
}

double meanAbsoluteError(Iterable<num> errors) {
  final values = errors.map((error) => error.toDouble()).toList();
  if (values.isEmpty) throw ArgumentError.value(errors, 'errors');
  return values.reduce((first, second) => first + second) / values.length;
}

ForecastModelType selectBestModel(Map<ForecastModelType, double> scores) {
  if (scores.isEmpty || scores.values.any((score) => !score.isFinite)) {
    throw ArgumentError.value(scores, 'scores');
  }
  final bestMae = scores.values.reduce(math.min);
  final tolerance = math.max(1e-9, bestMae.abs() * 0.01);
  for (final type in ForecastModelType.values) {
    final score = scores[type];
    if (score != null && score - bestMae <= tolerance) return type;
  }
  throw StateError('No forecast model score was selectable.');
}

bool _validSeries(List<TimeSeriesPoint> points) {
  if (points.length < 6) return false;
  for (var index = 0; index < points.length; index++) {
    final point = points[index];
    if (!point.value.isFinite || point.value < 0) return false;
    if (index > 0 && points[index - 1].period.compareTo(point.period) >= 0) {
      return false;
    }
  }
  return true;
}

double _nonNegative(double value) => math.max(0, value).toDouble();
