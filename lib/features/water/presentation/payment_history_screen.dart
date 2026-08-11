import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
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
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final payment = ordered[index];
                return ExpansionTile(
                  title: Text(payment.receiptNumber),
                  subtitle: Text(
                    '${WaterFormatters.date(payment.paymentDate)} · '
                    '${WaterFormatters.period(payment.paymentYear, payment.paymentMonth)}\n'
                    '${payment.paymentCenter}',
                  ),
                  trailing: Text(WaterFormatters.money(payment.amountCents)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
