import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:flutter/material.dart';

class BillingDetailScreen extends StatelessWidget {
  const BillingDetailScreen({required this.record, super.key});

  final BillingRecord record;

  @override
  Widget build(BuildContext context) => UtilityTheme(
    utilityType: UtilityType.water,
    child: Scaffold(
      appBar: AppBar(title: const Text('Detalle del recibo')),
      body: SafeArea(
        key: const Key('detailBottomSafeArea'),
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            InfoSectionCard(
              title: 'Resumen',
              utilityType: UtilityType.water,
              rows: [
                InfoRowData(
                  label: 'Período',
                  value: WaterFormatters.period(
                    record.billingYear,
                    record.billingMonth,
                  ),
                ),
                InfoRowData(
                  label: 'Número de recibo',
                  value: record.receiptNumber,
                ),
                InfoRowData(
                  label: 'Consumo',
                  value: '${_number(record.consumptionCubicMeters)} m³',
                ),
                InfoRowData(
                  label: 'Lectura promedio',
                  value: _number(record.averageReading),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InfoSectionCard(
              title: 'Facturación',
              utilityType: UtilityType.water,
              rows: [
                InfoRowData(
                  label: 'Importe del mes',
                  value: WaterFormatters.money(record.monthlyChargeCents),
                ),
                InfoRowData(
                  label: 'Meses atrasados',
                  value: record.overdueMonths.toString(),
                ),
                InfoRowData(
                  label: 'Deuda anterior',
                  value: WaterFormatters.money(record.outstandingDebtCents),
                ),
                InfoRowData(
                  label: 'Total',
                  value: WaterFormatters.money(record.totalAmountCents),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
