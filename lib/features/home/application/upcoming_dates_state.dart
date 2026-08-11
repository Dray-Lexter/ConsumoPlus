import '../domain/upcoming_dates_models.dart';

class UpcomingDatesState {
  UpcomingDatesState({
    this.isLoading = false,
    List<ServiceSchedule> schedules = const [],
  }) : schedules = List.unmodifiable(schedules);

  final bool isLoading;
  final List<ServiceSchedule> schedules;
}
