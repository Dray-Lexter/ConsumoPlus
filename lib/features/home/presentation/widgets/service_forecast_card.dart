import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:consumo_plus/features/home/forecast_copy.dart';
import 'package:flutter/material.dart';

class ServiceForecastCard extends StatelessWidget {
  const ServiceForecastCard({required this.forecast, super.key});

  final ServiceForecast forecast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _semanticLabel(),
      excludeSemantics: true,
      child: DecoratedBox(
        key: Key('forecastCard-${forecast.utilityType.name}'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ForecastHeader(forecast: forecast),
              const SizedBox(height: AppSpacing.md),
              if (forecast.hasEstimate)
                _AvailableForecast(forecast: forecast)
              else
                _UnavailableForecast(forecast: forecast),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    if (!forecast.hasEstimate) {
      final reason =
          forecast.insufficientReason == ForecastInsufficientReason.irregular
          ? ForecastCopy.irregularHistory
          : '${ForecastCopy.notEnoughTitle}. ${ForecastCopy.notEnoughDetail}';
      return '${forecast.serviceName}, ${forecast.providerName}. '
          '${ForecastCopy.insufficientStatus}. $reason';
    }
    final consumption = forecast.consumption!;
    final cost = forecast.cost!;
    return '${forecast.serviceName}, ${forecast.providerName}. '
        '${ForecastCopy.semanticTrend(forecast.trend!)}. '
        '${ForecastCopy.period(forecast.predictedPeriod!)}. '
        'Rango estimado de consumo: '
        '${ForecastCopy.consumptionRange(consumption, forecast.consumptionUnit)}. '
        'Rango estimado de pago: ${ForecastCopy.costRange(cost)}. '
        '${ForecastCopy.consumptionVariation(consumption.variationPercent)}. '
        '${ForecastCopy.costVariation(cost.variationPercent)}. '
        '${ForecastCopy.history(forecast.status, forecast.sampleCount)}. '
        '${ForecastCopy.orientative}.';
  }
}

class _ForecastHeader extends StatelessWidget {
  const _ForecastHeader({required this.forecast});

  final ServiceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final visual = forecast.utilityType.visual;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: visual.container,
            borderRadius: BorderRadius.circular(visual.iconRadius),
          ),
          child: Transform.rotate(
            angle: visual.iconRotationRadians,
            child: Icon(visual.icon, color: visual.accent, size: AppSpacing.lg),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forecast.serviceName,
                style: textTheme.labelLarge?.copyWith(color: visual.accent),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(forecast.providerName, style: textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailableForecast extends StatelessWidget {
  const _AvailableForecast({required this.forecast});

  final ServiceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = forecast.utilityType.visual;
    final consumption = forecast.consumption!;
    final cost = forecast.cost!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ForecastCopy.trend(forecast.trend!),
          style: textTheme.titleSmall?.copyWith(color: visual.accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          ForecastCopy.period(forecast.predictedPeriod!),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.md),
        _ForecastMetric(
          label: ForecastCopy.consumptionEstimate,
          value: ForecastCopy.consumptionRange(
            consumption,
            forecast.consumptionUnit,
          ),
          valueColor: visual.accent,
        ),
        const SizedBox(height: AppSpacing.md),
        _ForecastMetric(
          label: ForecastCopy.paymentEstimate,
          value: ForecastCopy.costRange(cost),
          valueColor: visual.accent,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          ForecastCopy.consumptionVariation(consumption.variationPercent),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          ForecastCopy.costVariation(cost.variationPercent),
          style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
        ),
        if (forecast.isHighlyVariable) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            ForecastCopy.variableHistory,
            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          ForecastCopy.history(forecast.status, forecast.sampleCount),
          style: textTheme.labelMedium?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          ForecastCopy.orientative,
          style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
        ),
      ],
    );
  }
}

class _UnavailableForecast extends StatelessWidget {
  const _UnavailableForecast({required this.forecast});

  final ServiceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ForecastCopy.insufficientStatus, style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (forecast.insufficientReason == ForecastInsufficientReason.irregular)
          Text(ForecastCopy.irregularHistory, style: textTheme.bodyMedium)
        else ...[
          Text(ForecastCopy.notEnoughTitle, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ForecastCopy.notEnoughDetail,
            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
          ),
        ],
      ],
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  const _ForecastMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: textTheme.titleMedium?.copyWith(color: valueColor)),
      ],
    );
  }
}
