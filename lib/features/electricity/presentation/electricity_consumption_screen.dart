import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/features/electricity/presentation/widgets/electricity_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_statistics.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';

class ElectricityConsumptionScreen extends StatelessWidget {
  const ElectricityConsumptionScreen({required this.records, super.key});
  final List<ElectricityConsumptionRecord> records;

  @override
  Widget build(BuildContext context) {
    final orderedRecords = [...records]
      ..sort((left, right) {
        final year = right.billingYear.compareTo(left.billingYear);
        return year != 0
            ? year
            : right.billingMonth.compareTo(left.billingMonth);
      });
    final chartPoints = visibleUtilityConsumptionPoints(
      electricityConsumptionPoints(orderedRecords),
      maxPeriods: 12,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Consumos')),
      body: orderedRecords.isEmpty
          ? const Center(child: Text('No hay consumos guardados.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Evolución del consumo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ElectricityConsumptionChart(
                  records: orderedRecords,
                  maxPeriods: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                UtilityConsumptionStatistics(
                  points: chartPoints,
                  maximumAveragePeriods: 6,
                  valueFormatter: (value) =>
                      ElectricityFormatters.energy((value * 1000).round()),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var index = 0; index < orderedRecords.length; index++) ...[
                  HistoryRecordCard(
                    key: Key(
                      'electricityConsumption-${orderedRecords[index].sourcePeriodCode}',
                    ),
                    utilityType: UtilityType.electricity,
                    title: ElectricityFormatters.period(
                      orderedRecords[index].billingYear,
                      orderedRecords[index].billingMonth,
                    ),
                    amount: ElectricityFormatters.energy(
                      orderedRecords[index].consumptionWh,
                    ),
                    details: [
                      '${orderedRecords[index].tariffCode} · '
                          '${ElectricityFormatters.money(orderedRecords[index].monthlyChargeCents)}',
                    ],
                    icon: Icons.bolt_outlined,
                  ),
                  if (index != orderedRecords.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}
