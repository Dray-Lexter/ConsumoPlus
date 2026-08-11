import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({required this.records, super.key});

  final List<PaymentRecord> records;

  @override
  Widget build(BuildContext context) {
    final ordered = [...records]
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pagos')),
      body: ordered.isEmpty
          ? const Center(child: Text('No hay pagos guardados.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final payment = ordered[index];
                return HistoryRecordCard(
                  key: Key('waterPayment-${payment.receiptNumber}'),
                  utilityType: UtilityType.water,
                  title: WaterFormatters.period(
                    payment.paymentYear,
                    payment.paymentMonth,
                  ),
                  amount: WaterFormatters.money(payment.amountCents),
                  overline: payment.receiptNumber,
                  details: [
                    WaterFormatters.date(payment.paymentDate),
                    payment.paymentCenter,
                  ],
                  icon: Icons.account_balance_wallet_outlined,
                  expandedDetails: [
                    Text('Centro de pago: ${payment.paymentCenter}'),
                    Text('Tipo: ${payment.documentType}'),
                    Text('Detalle: ${payment.detail}'),
                  ],
                );
              },
            ),
    );
  }
}
