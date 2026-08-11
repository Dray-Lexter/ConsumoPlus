import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/features/water/presentation/billing_detail_screen.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:flutter/material.dart';

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({required this.records, super.key});

  final List<BillingRecord> records;

  @override
  Widget build(BuildContext context) {
    final ordered = [...records]
      ..sort((a, b) {
        final year = b.billingYear.compareTo(a.billingYear);
        return year != 0 ? year : b.billingMonth.compareTo(a.billingMonth);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de recibos')),
      body: ordered.isEmpty
          ? const Center(child: Text('No hay recibos guardados.'))
          : ListView.separated(
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = ordered[index];
                return ListTile(
                  title: Text(
                    WaterFormatters.period(
                      record.billingYear,
                      record.billingMonth,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.receiptNumber),
                      Text('${record.consumptionCubicMeters} m³'),
                      Text(
                        'Mes: ${WaterFormatters.money(record.monthlyChargeCents)} · '
                        'Deuda: ${WaterFormatters.money(record.outstandingDebtCents)}',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    WaterFormatters.money(record.totalAmountCents),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: AppRoutes.waterBillingDetail,
                      ),
                      builder: (_) => BillingDetailScreen(record: record),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
