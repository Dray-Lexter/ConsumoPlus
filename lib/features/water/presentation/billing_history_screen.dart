import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/presentation/billing_detail_screen.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final record = ordered[index];
                return HistoryRecordCard(
                  key: Key('waterBill-${record.receiptNumber}'),
                  utilityType: UtilityType.water,
                  title: WaterFormatters.period(
                    record.billingYear,
                    record.billingMonth,
                  ),
                  amount: WaterFormatters.money(record.totalAmountCents),
                  overline: record.receiptNumber,
                  details: [
                    '${_number(record.consumptionCubicMeters)} m³',
                    'Importe ${WaterFormatters.money(record.monthlyChargeCents)} · '
                        'Deuda ${WaterFormatters.money(record.outstandingDebtCents)}',
                  ],
                  icon: Icons.receipt_long_outlined,
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

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
