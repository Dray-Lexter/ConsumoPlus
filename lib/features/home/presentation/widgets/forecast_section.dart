import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:consumo_plus/features/home/forecast_copy.dart';
import 'package:flutter/material.dart';

import 'service_forecast_card.dart';

class ForecastSection extends StatelessWidget {
  const ForecastSection({required this.forecasts, super.key});

  final List<ServiceForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('forecastSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ForecastCopy.sectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < forecasts.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          ServiceForecastCard(forecast: forecasts[index]),
        ],
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          container: true,
          label: ForecastCopy.disclaimer,
          excludeSemantics: true,
          child: Text(
            ForecastCopy.disclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
