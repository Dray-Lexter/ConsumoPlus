import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:flutter/material.dart';

class ElectricityAccountStatusScreen extends StatelessWidget {
  const ElectricityAccountStatusScreen({required this.status, super.key});
  final ElectricityAccountStatus status;

  @override
  Widget build(BuildContext context) => UtilityTheme(
    utilityType: UtilityType.electricity,
    child: Scaffold(
      appBar: AppBar(title: const Text('Estado de cuenta')),
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
            Text(
              ElectricityFormatters.period(
                status.billingYear,
                status.billingMonth,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            InfoSectionCard(
              title: 'Resumen económico',
              utilityType: UtilityType.electricity,
              rows: [
                InfoRowData(
                  label: 'Facturación del mes',
                  value: ElectricityFormatters.money(
                    status.currentBillingCents,
                  ),
                ),
                InfoRowData(
                  label: 'Deuda anterior',
                  value: ElectricityFormatters.money(status.previousDebtCents),
                ),
                InfoRowData(
                  label: 'Deuda total',
                  value: ElectricityFormatters.money(status.totalDebtCents),
                ),
                InfoRowData(
                  label: 'Monto pagado',
                  value: ElectricityFormatters.money(status.amountPaidCents),
                ),
                InfoRowData(
                  label: 'Saldo total',
                  value: ElectricityFormatters.money(status.totalBalanceCents),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InfoSectionCard(
              title: 'Fechas',
              utilityType: UtilityType.electricity,
              rows: [
                InfoRowData(label: 'Vencimiento', value: _date(status.dueDate)),
                InfoRowData(label: 'Emisión', value: _date(status.issueDate)),
                InfoRowData(label: 'Lectura', value: _date(status.readingDate)),
                InfoRowData(
                  label: 'Lectura anterior',
                  value: _date(status.previousReadingDate),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  static String _date(DateTime? value) => value == null
      ? 'No disponible en el portal'
      : ElectricityFormatters.date(value);
}
