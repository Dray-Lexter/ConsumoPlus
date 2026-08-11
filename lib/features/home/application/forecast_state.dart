import '../domain/forecast/service_forecast_calculator.dart';

class ForecastState {
  ForecastState({
    this.isLoading = false,
    List<ServiceForecast> forecasts = const [],
  }) : forecasts = List.unmodifiable(forecasts);

  final bool isLoading;
  final List<ServiceForecast> forecasts;
}
