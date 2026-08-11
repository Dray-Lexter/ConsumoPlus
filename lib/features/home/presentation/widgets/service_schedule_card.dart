import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:flutter/material.dart';

import 'schedule_progress_row.dart';

class ServiceScheduleCard extends StatelessWidget {
  const ServiceScheduleCard({required this.schedule, super.key});

  final ServiceSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final visual = schedule.utilityType.visual;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      key: Key('scheduleCard-${schedule.utilityType.name}'),
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
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: AppSpacing.xxl,
                    height: AppSpacing.xxl,
                    decoration: BoxDecoration(
                      color: visual.container,
                      borderRadius: BorderRadius.circular(visual.iconRadius),
                    ),
                    child: Transform.rotate(
                      angle: visual.iconRotationRadians,
                      child: Icon(
                        visual.icon,
                        color: visual.accent,
                        size: AppSpacing.lg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.serviceName,
                        style: textTheme.labelLarge?.copyWith(
                          color: visual.accent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(schedule.providerName, style: textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            for (final indicator in schedule.indicators) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              ScheduleProgressRow(
                key: Key(
                  'scheduleRow-${schedule.utilityType.name}-${indicator.type.name}',
                ),
                utilityType: schedule.utilityType,
                indicator: indicator,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
