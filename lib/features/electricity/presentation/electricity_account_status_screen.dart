import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:flutter/material.dart';

class ElectricityAccountStatusScreen extends StatelessWidget {
  const ElectricityAccountStatusScreen({required this.status, super.key});
  final ElectricityAccountStatus status;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Estado de cuenta')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          ElectricityFormatters.period(status.billingYear, status.billingMonth),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _Field(
          'Facturación del mes',
          ElectricityFormatters.money(status.currentBillingCents),
        ),
        _Field(
          'Deuda anterior',
          ElectricityFormatters.money(status.previousDebtCents),
        ),
        _Field(
          'Deuda total',
          ElectricityFormatters.money(status.totalDebtCents),
        ),
        _Field(
          'Monto pagado',
          ElectricityFormatters.money(status.amountPaidCents),
        ),
        _Field(
          'Saldo total',
          ElectricityFormatters.money(status.totalBalanceCents),
        ),
        _Field('Vencimiento', _date(status.dueDate)),
        _Field('Emisión', _date(status.issueDate)),
        _Field('Lectura', _date(status.readingDate)),
        _Field('Lectura anterior', _date(status.previousReadingDate)),
      ],
    ),
  );

  static String _date(DateTime? value) => value == null
      ? 'No disponible en el portal'
      : ElectricityFormatters.date(value);
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
  );
}
