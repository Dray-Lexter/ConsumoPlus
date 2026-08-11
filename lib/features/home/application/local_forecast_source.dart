import 'package:consumo_plus/core/config/service_providers.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';

import '../domain/forecast/forecast_models.dart';
import '../domain/forecast/service_forecast_calculator.dart';
import 'forecast_source.dart';

typedef ForecastWaterSnapshotLoader = Future<WaterSnapshot?> Function();
typedef ForecastElectricitySnapshotLoader =
    Future<ElectricitySnapshot?> Function();

class LocalForecastSource implements ForecastSource {
  const LocalForecastSource({
    required ForecastWaterSnapshotLoader loadWater,
    required ForecastElectricitySnapshotLoader loadElectricity,
  }) : _loadWater = loadWater,
       _loadElectricity = loadElectricity;

  final ForecastWaterSnapshotLoader _loadWater;
  final ForecastElectricitySnapshotLoader _loadElectricity;

  @override
  Future<List<ServiceForecastInput>> load() async {
    final snapshots = await Future.wait<Object?>([
      _loadWater(),
      _loadElectricity(),
    ]);
    final inputs = <ServiceForecastInput>[];
    final water = snapshots[0] as WaterSnapshot?;
    final electricity = snapshots[1] as ElectricitySnapshot?;
    if (water != null) inputs.add(_water(water));
    if (electricity != null) inputs.add(_electricity(electricity));
    return List.unmodifiable(inputs);
  }

  ServiceForecastInput _water(WaterSnapshot snapshot) {
    final account = snapshot.account;
    final records = snapshot.billingRecords.where(
      (record) =>
          record.providerId == account.providerId &&
          record.customerCode == account.customerCode,
    );
    return ServiceForecastInput(
      utilityType: epsTacnaProvider.utilityType,
      serviceName: 'Agua',
      providerName: epsTacnaProvider.displayName,
      consumptionUnit: 'm³',
      observations: [
        for (final record in records)
          MonthlyUtilityObservation(
            period: MonthPeriod(record.billingYear, record.billingMonth),
            consumption: record.consumptionCubicMeters,
            monthlyCostCents: record.monthlyChargeCents.toDouble(),
            synchronizedAt: record.synchronizedAt,
            sourceKey: record.naturalKey,
          ),
      ],
    );
  }

  ServiceForecastInput _electricity(ElectricitySnapshot snapshot) {
    final account = snapshot.account;
    final records = snapshot.consumptionRecords.where(
      (record) =>
          record.providerId == account.providerId &&
          record.contractNumber == account.contractNumber,
    );
    return ServiceForecastInput(
      utilityType: electrosurProvider.utilityType,
      serviceName: 'Electricidad',
      providerName: electrosurProvider.displayName,
      consumptionUnit: 'kWh',
      observations: [
        for (final record in records)
          MonthlyUtilityObservation(
            period: MonthPeriod(record.billingYear, record.billingMonth),
            consumption: record.consumptionWh / 1000.0,
            monthlyCostCents: record.monthlyChargeCents.toDouble(),
            synchronizedAt: record.synchronizedAt,
            sourceKey: record.naturalKey,
          ),
      ],
    );
  }
}
