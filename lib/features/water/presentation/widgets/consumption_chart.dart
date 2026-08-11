import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:flutter/material.dart';

class ConsumptionChart extends StatelessWidget {
  const ConsumptionChart({
    required this.records,
    required this.maxPeriods,
    super.key,
  });

  final List<BillingRecord> records;
  final int maxPeriods;

  @override
  Widget build(BuildContext context) {
    return UtilityConsumptionChart(
      utilityType: UtilityType.water,
      unit: 'm³',
      semanticTitle: 'Gráfico de consumo de Agua',
      points: waterConsumptionPoints(records),
      maxPeriods: maxPeriods,
    );
  }
}

List<UtilityConsumptionPoint> waterConsumptionPoints(
  List<BillingRecord> records,
) => [
  for (final record in records)
    UtilityConsumptionPoint(
      year: record.billingYear,
      month: record.billingMonth,
      value: record.consumptionCubicMeters,
      periodLabel: WaterFormatters.period(
        record.billingYear,
        record.billingMonth,
      ),
      displayValue: '${consumptionNumber(record.consumptionCubicMeters)} m³',
      semanticValue:
          '${consumptionNumber(record.consumptionCubicMeters)} metros cúbicos',
      contextualValue: WaterFormatters.money(record.totalAmountCents),
    ),
];

String consumptionNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
