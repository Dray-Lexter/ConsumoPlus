import 'package:consumo_plus/core/models/utility_type.dart';

import 'forecast_engine.dart';
import 'forecast_models.dart';

const forecastMaximumPeriods = 12;
const forecastMinimumPeriods = 6;
const forecastTrendThresholdPercent = 5.0;

enum ForecastStatus { insufficient, preliminary, sufficient }

enum ForecastInsufficientReason { notEnoughHistory, irregular }

enum TrendClassification { favorable, stable, rising }

class MonthlyUtilityObservation {
  const MonthlyUtilityObservation({
    required this.period,
    required this.consumption,
    required this.monthlyCostCents,
    required this.synchronizedAt,
    required this.sourceKey,
  });

  final MonthPeriod period;
  final double consumption;
  final double monthlyCostCents;
  final DateTime synchronizedAt;
  final String sourceKey;
}

class ServiceForecastInput {
  ServiceForecastInput({
    required this.utilityType,
    required this.serviceName,
    required this.providerName,
    required this.consumptionUnit,
    required List<MonthlyUtilityObservation> observations,
  }) : observations = List.unmodifiable(observations);

  final UtilityType utilityType;
  final String serviceName;
  final String providerName;
  final String consumptionUnit;
  final List<MonthlyUtilityObservation> observations;
}

class ServiceForecast {
  const ServiceForecast({
    required this.utilityType,
    required this.serviceName,
    required this.providerName,
    required this.consumptionUnit,
    required this.sampleCount,
    required this.status,
    required this.insufficientReason,
    required this.predictedPeriod,
    required this.consumption,
    required this.cost,
    required this.trend,
  });

  final UtilityType utilityType;
  final String serviceName;
  final String providerName;
  final String consumptionUnit;
  final int sampleCount;
  final ForecastStatus status;
  final ForecastInsufficientReason? insufficientReason;
  final MonthPeriod? predictedPeriod;
  final SeriesForecast? consumption;
  final SeriesForecast? cost;
  final TrendClassification? trend;

  bool get hasEstimate => consumption != null && cost != null;
  bool get isHighlyVariable =>
      consumption?.isHighlyVariable == true || cost?.isHighlyVariable == true;
}

class ServiceForecastCalculator {
  const ServiceForecastCalculator({
    this.engine = const ForecastEngine(),
    this.maximumPeriods = forecastMaximumPeriods,
  });

  final ForecastEngine engine;
  final int maximumPeriods;

  List<ServiceForecast> build(List<ServiceForecastInput> inputs) =>
      List.unmodifiable(inputs.map(_buildService));

  ServiceForecast _buildService(ServiceForecastInput input) {
    final observations = _prepare(input.observations);
    if (observations.length < forecastMinimumPeriods) {
      return _insufficient(
        input,
        observations.length,
        ForecastInsufficientReason.notEnoughHistory,
      );
    }

    final consumption = engine.forecast([
      for (final observation in observations)
        TimeSeriesPoint(
          period: observation.period,
          value: observation.consumption,
        ),
    ]);
    final cost = engine.forecast([
      for (final observation in observations)
        TimeSeriesPoint(
          period: observation.period,
          value: observation.monthlyCostCents,
        ),
    ]);
    if (consumption == null || cost == null) {
      return _insufficient(
        input,
        observations.length,
        ForecastInsufficientReason.irregular,
      );
    }

    return ServiceForecast(
      utilityType: input.utilityType,
      serviceName: input.serviceName,
      providerName: input.providerName,
      consumptionUnit: input.consumptionUnit,
      sampleCount: observations.length,
      status: observations.length >= maximumPeriods
          ? ForecastStatus.sufficient
          : ForecastStatus.preliminary,
      insufficientReason: null,
      predictedPeriod: consumption.predictedPeriod,
      consumption: consumption,
      cost: cost,
      trend: classifyConsumptionTrend(consumption.variationPercent),
    );
  }

  ServiceForecast _insufficient(
    ServiceForecastInput input,
    int sampleCount,
    ForecastInsufficientReason reason,
  ) => ServiceForecast(
    utilityType: input.utilityType,
    serviceName: input.serviceName,
    providerName: input.providerName,
    consumptionUnit: input.consumptionUnit,
    sampleCount: sampleCount,
    status: ForecastStatus.insufficient,
    insufficientReason: reason,
    predictedPeriod: null,
    consumption: null,
    cost: null,
    trend: null,
  );

  List<MonthlyUtilityObservation> _prepare(
    List<MonthlyUtilityObservation> observations,
  ) {
    final byPeriod = <MonthPeriod, MonthlyUtilityObservation>{};
    for (final observation in observations) {
      if (!_isValid(observation)) continue;
      final current = byPeriod[observation.period];
      if (current == null || _prefer(observation, current)) {
        byPeriod[observation.period] = observation;
      }
    }
    final ordered = byPeriod.values.toList()
      ..sort((left, right) => left.period.compareTo(right.period));
    final start = ordered.length > maximumPeriods
        ? ordered.length - maximumPeriods
        : 0;
    return List.unmodifiable(ordered.sublist(start));
  }

  static bool _isValid(MonthlyUtilityObservation observation) =>
      observation.consumption.isFinite &&
      observation.consumption >= 0 &&
      observation.monthlyCostCents.isFinite &&
      observation.monthlyCostCents >= 0 &&
      observation.sourceKey.isNotEmpty;

  static bool _prefer(
    MonthlyUtilityObservation candidate,
    MonthlyUtilityObservation current,
  ) {
    final synchronized = candidate.synchronizedAt.compareTo(
      current.synchronizedAt,
    );
    if (synchronized != 0) return synchronized > 0;
    return candidate.sourceKey.compareTo(current.sourceKey) > 0;
  }
}

TrendClassification? classifyConsumptionTrend(double? variationPercent) {
  if (variationPercent == null || !variationPercent.isFinite) return null;
  if (variationPercent <= -forecastTrendThresholdPercent) {
    return TrendClassification.favorable;
  }
  if (variationPercent >= forecastTrendThresholdPercent) {
    return TrendClassification.rising;
  }
  return TrendClassification.stable;
}
