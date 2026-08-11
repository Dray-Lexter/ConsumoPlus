import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:flutter/material.dart';

class ElectricityPaymentScreen extends StatelessWidget {
  const ElectricityPaymentScreen({required this.records, super.key});
  final List<ElectricityPaymentRecord> records;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pagos')),
    body: records.isEmpty
        ? const Center(child: Text('No hay pagos guardados.'))
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                child: ListTile(
                  title: Text(ElectricityFormatters.money(record.amountCents)),
                  subtitle: Text(
                    '${ElectricityFormatters.date(record.paymentDate)} · '
                    '${record.paymentCenter}\nPeriodo ${record.sourcePeriodCode}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
  );
}
