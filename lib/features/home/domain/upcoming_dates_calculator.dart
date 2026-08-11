import 'dart:math' as math;

import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/upcoming_dates_copy.dart';

import 'upcoming_dates_models.dart';
import 'water_billing_schedule.dart';

class UpcomingDatesCalculator {
  const UpcomingDatesCalculator({
    this.waterSchedule = epsTacnaWaterBillingSchedule,
  });

  final WaterBillingSchedule waterSchedule;

  List<ServiceSchedule> build({
    required UpcomingDatesInput input,
    required DateTime now,
  }) {
    final today = localDate(now);
    final schedules = <ServiceSchedule>[];
    if (input.waterConnected) schedules.add(_water(today));
    if (input.electricityConnected) {
      schedules.add(
        _electricity(
          today,
          issueDate: input.electricityIssueDate,
          dueDate: input.electricityDueDate,
        ),
      );
    }
    return List.unmodifiable(schedules);
  }

  ServiceSchedule _water(DateTime today) {
    final issueDate = _nextDayOfMonth(today, waterSchedule.expectedIssueDay);
    final dueDate = _nextDayOfMonth(today, waterSchedule.expectedDueDay);
    return ServiceSchedule(
      utilityType: UtilityType.water,
      serviceName: UpcomingDatesCopy.waterService,
      providerName: UpcomingDatesCopy.waterProvider,
      indicators: [
        _datedIndicator(
          serviceName: UpcomingDatesCopy.waterService,
          type: ScheduleIndicatorType.issue,
          label: UpcomingDatesCopy.estimatedIssue,
          date: issueDate,
          today: today,
          isEstimated: true,
          progress: _monthlyProgress(today, issueDate),
        ),
        _datedIndicator(
          serviceName: UpcomingDatesCopy.waterService,
          type: ScheduleIndicatorType.due,
          label: UpcomingDatesCopy.estimatedDue,
          date: dueDate,
          today: today,
          isEstimated: true,
          progress: _monthlyProgress(today, dueDate),
        ),
      ],
    );
  }

  ServiceSchedule _electricity(
    DateTime today, {
    required DateTime? issueDate,
    required DateTime? dueDate,
  }) {
    final localIssue = issueDate == null ? null : localDate(issueDate);
    final localDue = dueDate == null ? null : localDate(dueDate);
    final indicators = <ScheduleIndicator>[];

    if (localIssue != null) {
      var monthOffset = 1;
      var nextIssue = addCalendarMonths(localIssue, monthOffset);
      while (nextIssue.isBefore(today)) {
        monthOffset += 1;
        nextIssue = addCalendarMonths(localIssue, monthOffset);
      }
      indicators.add(
        _datedIndicator(
          serviceName: UpcomingDatesCopy.electricityService,
          type: ScheduleIndicatorType.issue,
          label: UpcomingDatesCopy.estimatedIssue,
          date: nextIssue,
          today: today,
          isEstimated: true,
          progress: cycleProgress(
            now: today,
            start: addCalendarMonths(localIssue, monthOffset - 1),
            end: nextIssue,
          ),
        ),
      );
    }

    final staleBoundary = localIssue == null
        ? null
        : addCalendarMonths(localIssue, 1);
    final dueIsStale =
        (staleBoundary != null && !today.isBefore(staleBoundary)) ||
        (localIssue == null && localDue != null && localDue.isBefore(today));
    if (localDue == null || dueIsStale) {
      indicators.add(_pendingElectricityDue());
    } else {
      indicators.add(
        _datedIndicator(
          serviceName: UpcomingDatesCopy.electricityService,
          type: ScheduleIndicatorType.due,
          label: UpcomingDatesCopy.officialDue,
          date: localDue,
          today: today,
          isEstimated: false,
          progress: localIssue == null
              ? null
              : cycleProgress(now: today, start: localIssue, end: localDue),
        ),
      );
    }

    return ServiceSchedule(
      utilityType: UtilityType.electricity,
      serviceName: UpcomingDatesCopy.electricityService,
      providerName: UpcomingDatesCopy.electricityProvider,
      indicators: indicators,
    );
  }

  ScheduleIndicator _pendingElectricityDue() {
    return const ScheduleIndicator(
      type: ScheduleIndicatorType.pendingDue,
      label: UpcomingDatesCopy.pendingDue,
      distanceText: '',
      isEstimated: false,
      secondaryText: UpcomingDatesCopy.pendingDueDetail,
      semanticsLabel:
          '${UpcomingDatesCopy.electricityService}. '
          '${UpcomingDatesCopy.pendingDue}. '
          '${UpcomingDatesCopy.pendingDueDetail}',
    );
  }

  ScheduleIndicator _datedIndicator({
    required String serviceName,
    required ScheduleIndicatorType type,
    required String label,
    required DateTime date,
    required DateTime today,
    required bool isEstimated,
    required double? progress,
  }) {
    final distance = _distanceText(type, today, date);
    return ScheduleIndicator(
      type: type,
      label: label,
      date: date,
      shortDateText: UpcomingDatesCopy.shortDate(date),
      distanceText: distance,
      isEstimated: isEstimated,
      progress: progress,
      semanticsLabel:
          '$serviceName. $label el ${UpcomingDatesCopy.fullDate(date)}. '
          '$distance.',
    );
  }

  DateTime _nextDayOfMonth(DateTime today, int day) {
    var target = _dateForDay(today.year, today.month, day);
    if (target.isBefore(today)) {
      final nextMonth = DateTime(today.year, today.month + 1);
      target = _dateForDay(nextMonth.year, nextMonth.month, day);
    }
    return target;
  }

  double _monthlyProgress(DateTime today, DateTime target) {
    final previousMonth = DateTime(target.year, target.month - 1);
    final start = _dateForDay(
      previousMonth.year,
      previousMonth.month,
      target.day,
    );
    return cycleProgress(now: today, start: start, end: target);
  }
}

DateTime localDate(DateTime value) {
  final local = value.isUtc ? value.toLocal() : value;
  return DateTime(local.year, local.month, local.day);
}

DateTime addCalendarMonths(DateTime value, int months) {
  final date = localDate(value);
  final monthIndex = date.year * 12 + date.month - 1 + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  return _dateForDay(year, month, date.day);
}

double cycleProgress({
  required DateTime now,
  required DateTime start,
  required DateTime end,
}) {
  final normalizedNow = localDate(now);
  final normalizedStart = localDate(start);
  final normalizedEnd = localDate(end);
  final totalDays = normalizedEnd.difference(normalizedStart).inDays;
  if (totalDays <= 0) return 0;
  final elapsedDays = normalizedNow.difference(normalizedStart).inDays;
  return (elapsedDays / totalDays).clamp(0.0, 1.0).toDouble();
}

DateTime _dateForDay(int year, int month, int requestedDay) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(requestedDay, lastDay));
}

String _distanceText(
  ScheduleIndicatorType type,
  DateTime today,
  DateTime event,
) {
  final days = event.difference(today).inDays;
  if (days == 0) {
    return type == ScheduleIndicatorType.issue
        ? UpcomingDatesCopy.expectedToday
        : UpcomingDatesCopy.dueToday;
  }
  if (days > 0) return UpcomingDatesCopy.futureDistance(days);
  final elapsed = -days;
  return UpcomingDatesCopy.pastDueDistance(elapsed);
}
