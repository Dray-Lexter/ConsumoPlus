import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:flutter/material.dart';

class UtilityConsumptionStatistics extends StatelessWidget {
  const UtilityConsumptionStatistics({
    required this.points,
    required this.maximumAveragePeriods,
    required this.valueFormatter,
    super.key,
  }) : assert(maximumAveragePeriods > 0);

  final List<UtilityConsumptionPoint> points;
  final int maximumAveragePeriods;
  final String Function(double value) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final ordered = [...points]
      ..sort((left, right) {
        final year = left.year.compareTo(right.year);
        return year != 0 ? year : left.month.compareTo(right.month);
      });
    final averagePoints = ordered.length > maximumAveragePeriods
        ? ordered.sublist(ordered.length - maximumAveragePeriods)
        : ordered;
    final average =
        averagePoints.fold<double>(0, (sum, point) => sum + point.value) /
        averagePoints.length;
    final maximum = ordered.reduce(
      (current, candidate) =>
          candidate.value > current.value ? candidate : current,
    );
    final minimum = ordered.reduce(
      (current, candidate) =>
          candidate.value < current.value ? candidate : current,
    );
    final periodWord = averagePoints.length == 1 ? 'mes' : 'meses';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          _StatisticRow(
            label: 'Promedio ${averagePoints.length} $periodWord',
            value: valueFormatter(average),
          ),
          const Divider(height: 1),
          _StatisticRow(
            label: 'Mayor consumo',
            value: '${maximum.periodLabel} · ${valueFormatter(maximum.value)}',
          ),
          const Divider(height: 1),
          _StatisticRow(
            label: 'Menor consumo',
            value: '${minimum.periodLabel} · ${valueFormatter(minimum.value)}',
          ),
        ],
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
}
