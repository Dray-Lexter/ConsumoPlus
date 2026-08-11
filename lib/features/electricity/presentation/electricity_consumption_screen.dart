import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/features/electricity/presentation/widgets/electricity_consumption_chart.dart';
import 'package:flutter/material.dart';

class ElectricityConsumptionScreen extends StatelessWidget {
  const ElectricityConsumptionScreen({required this.records, super.key});
  final List<ElectricityConsumptionRecord> records;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consumos')),
    body: records.isEmpty
        ? const Center(child: Text('No hay consumos guardados.'))
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Evolución del consumo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ElectricityConsumptionChart(records: records),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < records.length; index++) ...[
                Semantics(
                  label: 'Consumo ${records[index].sourcePeriodCode}',
                  child: Card(
                    child: ListTile(
                      title: Text(
                        ElectricityFormatters.period(
                          records[index].billingYear,
                          records[index].billingMonth,
                        ),
                      ),
                      subtitle: Text(
                        '${records[index].tariffCode} · ${ElectricityFormatters.money(records[index].monthlyChargeCents)}',
                      ),
                      trailing: Text(
                        ElectricityFormatters.energy(
                          records[index].consumptionWh,
                        ),
                      ),
                    ),
                  ),
                ),
                if (index != records.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
  );
}
