import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:consumo_plus/features/water/presentation/widgets/consumption_chart.dart';
import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hola, ${snapshot.account.ownerName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ultima actualizacion: ${WaterFormatters.dateTime(snapshot.synchronization.lastSuccessfulSyncAt ?? snapshot.account.synchronizedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (shouldRecommendUpdate) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text('Hay un nuevo mes. Puedes actualizar cuando lo desees.'),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('updateWaterData'),
          onPressed: busy ? null : onUpdate,
          icon: busy
              ? const SizedBox.square(
                  dimension: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(busy ? 'Actualizando...' : 'Actualizar con mi clave'),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (latest == null)
          const Text('Todavia no hay recibos guardados.')
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
            'Consumo por periodo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ConsumptionChart(records: snapshot.billingRecords),
        ],
        const SizedBox(height: AppSpacing.lg),
        _NavigationTile(
          key: const Key('openBillingHistory'),
          title: 'Historial de recibos',
          subtitle: '${snapshot.billingRecords.length} guardados',
          icon: Icons.receipt_long_outlined,
          onTap: onBilling,
        ),
        _NavigationTile(
          key: const Key('openPaymentHistory'),
          title: 'Historial de pagos',
          subtitle: '${snapshot.paymentRecords.length} guardados',
          icon: Icons.account_balance_wallet_outlined,
          onTap: onPayments,
        ),
        _NavigationTile(
          key: const Key('openSupplyDetails'),
          title: 'Datos del suministro',
          subtitle: snapshot.account.customerCode,
          icon: Icons.home_outlined,
          onTap: onSupply,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          key: const Key('deleteWaterData'),
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Borrar copia local'),
        ),
      ],
    );
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String _variation(double current, double previous) {
    final difference = current - previous;
    if (difference == 0) return 'Sin variacion respecto al periodo anterior.';
    final direction = difference > 0 ? 'Aumento' : 'Reduccion';
    return '$direction de ${_number(difference.abs())} m³ respecto al periodo anterior.';
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

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.water),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
