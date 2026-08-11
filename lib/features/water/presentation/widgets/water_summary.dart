import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/features/water/presentation/widgets/consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_statistics.dart';
import 'package:consumo_plus/shared/widgets/utility_access_tile.dart';
import 'package:consumo_plus/shared/widgets/utility_greeting.dart';
import 'package:flutter/material.dart';
import 'package:consumo_plus/shared/widgets/utility_update_button.dart';
import 'package:consumo_plus/shared/widgets/utility_sensitive_actions.dart';

class WaterSummary extends StatelessWidget {
  const WaterSummary({
    required this.snapshot,
    required this.shouldRecommendUpdate,
    required this.busy,
    required this.onUpdate,
    required this.onBilling,
    required this.onPayments,
    required this.onSupply,
    required this.onDelete,
    super.key,
  });

  final WaterSnapshot snapshot;
  final bool shouldRecommendUpdate;
  final bool busy;
  final VoidCallback onUpdate;
  final VoidCallback onBilling;
  final VoidCallback onPayments;
  final VoidCallback onSupply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latestBilling;
    final chronological = snapshot.billingChronological;
    final previous = chronological.length > 1
        ? chronological[chronological.length - 2]
        : null;
    final chartPoints = visibleUtilityConsumptionPoints(
      waterConsumptionPoints(snapshot.billingRecords),
      maxPeriods: 6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UtilityGreeting(ownerName: snapshot.account.ownerName),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Última actualización: ${WaterFormatters.dateTime(snapshot.synchronization.lastSuccessfulSyncAt ?? snapshot.account.synchronizedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (shouldRecommendUpdate) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text('Hay un nuevo mes. Puedes actualizar cuando lo desees.'),
        ],
        const SizedBox(height: AppSpacing.md),
        UtilityUpdateButton(
          key: const Key('updateWaterData'),
          utilityType: UtilityType.water,
          busy: busy,
          onPressed: onUpdate,
          label: 'Actualizar con mi clave',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (latest == null)
          const Text('Todavía no hay recibos guardados.')
        else ...[
          Text(
            WaterFormatters.period(latest.billingYear, latest.billingMonth),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            label: 'Consumo',
            value: '${_number(latest.consumptionCubicMeters)} m³',
            icon: Icons.water_drop_outlined,
            emphasized: true,
          ),
          if (previous != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _variation(
                latest.consumptionCubicMeters,
                previous.consumptionCubicMeters,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            label: 'Importe del mes',
            value: WaterFormatters.money(latest.monthlyChargeCents),
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            label: 'Deuda anterior',
            value: WaterFormatters.money(latest.outstandingDebtCents),
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            label: 'Total del recibo',
            value: WaterFormatters.money(latest.totalAmountCents),
            icon: Icons.payments_outlined,
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Consumo por período',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ConsumptionChart(records: snapshot.billingRecords, maxPeriods: 6),
          const SizedBox(height: AppSpacing.md),
          UtilityConsumptionStatistics(
            points: chartPoints,
            maximumAveragePeriods: 6,
            valueFormatter: (value) => '${_number(value)} m³',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Explora tus datos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        UtilityAccessTile(
          key: const Key('openBillingHistory'),
          utilityType: UtilityType.water,
          title: 'Historial de recibos',
          subtitle: '${snapshot.billingRecords.length} guardados',
          icon: Icons.receipt_long_outlined,
          onTap: onBilling,
        ),
        const SizedBox(height: AppSpacing.sm),
        UtilityAccessTile(
          key: const Key('openPaymentHistory'),
          utilityType: UtilityType.water,
          title: 'Historial de pagos',
          subtitle: '${snapshot.paymentRecords.length} guardados',
          icon: Icons.account_balance_wallet_outlined,
          onTap: onPayments,
        ),
        const SizedBox(height: AppSpacing.sm),
        UtilityAccessTile(
          key: const Key('openSupplyDetails'),
          utilityType: UtilityType.water,
          title: 'Datos del suministro',
          subtitle: 'Información de la cuenta',
          icon: Icons.home_outlined,
          onTap: onSupply,
        ),
        const SizedBox(height: AppSpacing.lg),
        DestructiveActionButton(
          key: const Key('deleteWaterData'),
          onPressed: busy ? null : onDelete,
          label: 'Eliminar datos de Agua',
        ),
      ],
    );
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String _variation(double current, double previous) {
    final difference = current - previous;
    if (difference == 0) return 'Sin variación respecto al período anterior.';
    final direction = difference > 0 ? 'Aumento' : 'Reducción';
    return '$direction de ${_number(difference.abs())} m³ respecto al período anterior.';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: emphasized ? AppColors.waterContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.water),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label)),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: emphasized ? AppColors.water : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
