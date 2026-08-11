import '../domain/forecast/service_forecast_calculator.dart';

abstract interface class ForecastSource {
  Future<List<ServiceForecastInput>> load();
}
