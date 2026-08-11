import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:flutter/material.dart';

class BillingDetailScreen extends StatelessWidget {
  const BillingDetailScreen({required this.record, super.key});

  final BillingRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del recibo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Detail(
            'Periodo',
            WaterFormatters.period(record.billingYear, record.billingMonth),
          ),
          _Detail('Numero de recibo', record.receiptNumber),
          _Detail('Consumo', '${record.consumptionCubicMeters} m³'),
          _Detail('Lectura promedio', record.averageReading.toString()),
          _Detail(
            'Importe del mes',
            WaterFormatters.money(record.monthlyChargeCents),
          ),
          _Detail('Meses atrasados', record.overdueMonths.toString()),
          _Detail(
            'Deuda anterior',
            WaterFormatters.money(record.outstandingDebtCents),
          ),
          _Detail('Total', WaterFormatters.money(record.totalAmountCents)),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
  );
}
