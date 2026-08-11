import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';

class ElectricityPaymentScreen extends StatelessWidget {
  const ElectricityPaymentScreen({required this.records, super.key});
  final List<ElectricityPaymentRecord> records;

  @override
  Widget build(BuildContext context) {
    final ordered = [...records]
      ..sort((left, right) => right.paymentDate.compareTo(left.paymentDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos')),
      body: ordered.isEmpty
          ? const Center(child: Text('No hay pagos guardados.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final record = ordered[index];
                return HistoryRecordCard(
                  key: Key('electricityPayment-${record.sourcePeriodCode}'),
                  utilityType: UtilityType.electricity,
                  title: ElectricityFormatters.period(
                    record.billingYear,
                    record.billingMonth,
                  ),
                  amount: ElectricityFormatters.money(record.amountCents),
                  details: [
                    ElectricityFormatters.date(record.paymentDate),
                    record.paymentCenter,
                  ],
                  icon: Icons.payments_outlined,
                );
              },
            ),
    );
  }
}
