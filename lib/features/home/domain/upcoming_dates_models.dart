import 'package:consumo_plus/core/models/utility_type.dart';

enum ScheduleIndicatorType { issue, due, pendingDue }

class UpcomingDatesInput {
  const UpcomingDatesInput({
    required this.waterConnected,
    required this.electricityConnected,
    this.electricityIssueDate,
    this.electricityDueDate,
  });

  final bool waterConnected;
  final bool electricityConnected;
  final DateTime? electricityIssueDate;
  final DateTime? electricityDueDate;
}

class ScheduleIndicator {
  const ScheduleIndicator({
    required this.type,
    required this.label,
    required this.distanceText,
    required this.isEstimated,
    required this.semanticsLabel,
    this.date,
    this.shortDateText,
    this.progress,
    this.secondaryText,
  });

  final ScheduleIndicatorType type;
  final String label;
  final DateTime? date;
  final String? shortDateText;
  final String distanceText;
  final bool isEstimated;
  final double? progress;
  final String? secondaryText;
  final String semanticsLabel;
}

class ServiceSchedule {
  ServiceSchedule({
    required this.utilityType,
    required this.serviceName,
    required this.providerName,
    required List<ScheduleIndicator> indicators,
  }) : indicators = List.unmodifiable(indicators);

  final UtilityType utilityType;
  final String serviceName;
  final String providerName;
  final List<ScheduleIndicator> indicators;
}
