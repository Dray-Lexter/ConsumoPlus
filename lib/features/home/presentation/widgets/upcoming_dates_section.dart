import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:consumo_plus/features/home/upcoming_dates_copy.dart';
import 'package:flutter/material.dart';

import 'service_schedule_card.dart';

class UpcomingDatesSection extends StatelessWidget {
  const UpcomingDatesSection({required this.schedules, super.key});

  final List<ServiceSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('upcomingDatesSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UpcomingDatesCopy.sectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < schedules.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          ServiceScheduleCard(schedule: schedules[index]),
        ],
      ],
    );
  }
}
