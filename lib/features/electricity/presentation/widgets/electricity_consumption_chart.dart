import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:flutter/material.dart';

class ElectricityConsumptionChart extends StatelessWidget {
  const ElectricityConsumptionChart({
    required this.records,
    required this.maxPeriods,
    super.key,
  });

  final List<ElectricityConsumptionRecord> records;
  final int maxPeriods;

  @override
  Widget build(BuildContext context) {
    return UtilityConsumptionChart(
      key: const Key('electricityConsumptionChart'),
      utilityType: UtilityType.electricity,
      unit: 'kWh',
      semanticTitle: 'Gráfico de consumo eléctrico',
      points: electricityConsumptionPoints(records),
      maxPeriods: maxPeriods,
    );
  }
}

List<UtilityConsumptionPoint> electricityConsumptionPoints(
  List<ElectricityConsumptionRecord> records,
) => [
  for (final record in records)
    UtilityConsumptionPoint(
      year: record.billingYear,
      month: record.billingMonth,
      value: record.consumptionWh / 1000,
      periodLabel: ElectricityFormatters.period(
        record.billingYear,
        record.billingMonth,
      ),
      displayValue: ElectricityFormatters.energy(record.consumptionWh),
      semanticValue: ElectricityFormatters.energy(record.consumptionWh),
      contextualValue: ElectricityFormatters.money(record.monthlyChargeCents),
    ),
];
