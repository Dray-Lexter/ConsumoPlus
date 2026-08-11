import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:consumo_plus/features/electricity/presentation/widgets/electricity_consumption_chart.dart';
import 'package:flutter/material.dart';
import 'package:consumo_plus/shared/widgets/utility_update_button.dart';
import 'package:consumo_plus/shared/widgets/utility_sensitive_actions.dart';
import 'package:consumo_plus/shared/widgets/utility_access_tile.dart';
import 'package:consumo_plus/shared/widgets/utility_greeting.dart';

class ElectricitySummary extends StatelessWidget {
  const ElectricitySummary({
    required this.snapshot,
    required this.busy,
    required this.shouldRecommendUpdate,
    required this.onUpdate,
    required this.onStatus,
    required this.onConsumptions,
    required this.onPayments,
    required this.onSupply,
    required this.onDelete,
    super.key,
  });

  final ElectricitySnapshot snapshot;
  final bool busy;
  final bool shouldRecommendUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onStatus;
  final VoidCallback onConsumptions;
  final VoidCallback onPayments;
  final VoidCallback onSupply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = snapshot.latestAccountStatus;
    final usage = snapshot.latestConsumption;
    final previous = snapshot.previousConsumption;
    final variation =
        usage == null || previous == null || previous.consumptionWh == 0
        ? null
        : (usage.consumptionWh - previous.consumptionWh) /
              previous.consumptionWh *
              100;
    return Semantics(
      label: 'Resumen de Electricidad',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UtilityGreeting(ownerName: snapshot.account.ownerName),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Última actualización: '
            '${ElectricityFormatters.dateTime(snapshot.synchronization.lastSuccessfulSyncAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (shouldRecommendUpdate) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('Hay un nuevo mes. Puedes actualizar cuando lo desees.'),
          ],
          const SizedBox(height: AppSpacing.md),
          UtilityUpdateButton(
            key: const Key('updateElectricityData'),
            utilityType: UtilityType.electricity,
            busy: busy,
            onPressed: onUpdate,
            label: 'Actualizar con mi clave',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.electricityContainer,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == null
                      ? 'Último período'
                      : ElectricityFormatters.period(
                          status.billingYear,
                          status.billingMonth,
                        ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  usage == null
                      ? 'Consumo no disponible'
                      : ElectricityFormatters.energy(usage.consumptionWh),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.electricity,
                  ),
                ),
                if (variation != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_variationText(variation)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (status != null)
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    _MoneyRow(
                      'Facturación del mes',
                      status.currentBillingCents,
                    ),
                    _MoneyRow('Deuda anterior', status.previousDebtCents),
                    _MoneyRow('Deuda total', status.totalDebtCents),
                    _MoneyRow('Saldo pendiente', status.totalBalanceCents),
                    if (status.dueDate != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vencimiento'),
                        trailing: Text(
                          ElectricityFormatters.date(status.dueDate!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (snapshot.consumptionRecords.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Consumo por período',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElectricityConsumptionChart(
              records: snapshot.consumptionRecords,
              maxPeriods: 6,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Explora tus datos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          UtilityAccessTile(
            key: const Key('openElectricityStatus'),
            utilityType: UtilityType.electricity,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Estado de cuenta',
            onTap: onStatus,
          ),
          const SizedBox(height: AppSpacing.sm),
          UtilityAccessTile(
            key: const Key('openElectricityConsumptions'),
            utilityType: UtilityType.electricity,
            icon: Icons.insights_outlined,
            title: 'Consumos',
            onTap: onConsumptions,
          ),
          const SizedBox(height: AppSpacing.sm),
          UtilityAccessTile(
            key: const Key('openElectricityPayments'),
            utilityType: UtilityType.electricity,
            icon: Icons.payments_outlined,
            title: 'Pagos',
            onTap: onPayments,
          ),
          const SizedBox(height: AppSpacing.sm),
          UtilityAccessTile(
            key: const Key('openElectricitySupply'),
            utilityType: UtilityType.electricity,
            icon: Icons.home_outlined,
            title: 'Datos del suministro',
            onTap: onSupply,
          ),
          const SizedBox(height: AppSpacing.lg),
          DestructiveActionButton(
            key: const Key('deleteElectricityData'),
            onPressed: busy ? null : onDelete,
            label: 'Eliminar datos de Electricidad',
          ),
        ],
      ),
    );
  }

  static String _variationText(double variation) {
    if (variation == 0) return 'Sin variación respecto al mes anterior';
    final percentage = variation.abs().toStringAsFixed(1).replaceAll('.', ',');
    final direction = variation > 0 ? 'más' : 'menos';
    return '$percentage % $direction que el mes anterior';
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      ElectricityFormatters.money(value),
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}
