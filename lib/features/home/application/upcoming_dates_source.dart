import '../domain/upcoming_dates_models.dart';

abstract interface class UpcomingDatesSource {
  Future<UpcomingDatesInput> load();
}
