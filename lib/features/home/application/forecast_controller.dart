import 'package:flutter/foundation.dart';

import '../domain/forecast/service_forecast_calculator.dart';
import 'forecast_source.dart';
import 'forecast_state.dart';

typedef ForecastControllerFactory = Future<ForecastController> Function();

class ForecastController extends ChangeNotifier {
  ForecastController({
    required ForecastSource source,
    ServiceForecastCalculator calculator = const ServiceForecastCalculator(),
  }) : _source = source,
       _calculator = calculator;

  final ForecastSource _source;
  final ServiceForecastCalculator _calculator;

  ForecastState _state = ForecastState();
  var _disposed = false;

  ForecastState get state => _state;

  Future<void> refresh() async {
    _setState(ForecastState(isLoading: true, forecasts: _state.forecasts));
    try {
      final inputs = await _source.load();
      _setState(ForecastState(forecasts: _calculator.build(inputs)));
    } on Object {
      _setState(ForecastState());
    }
  }

  void _setState(ForecastState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  String toString() =>
      'ForecastController(services: ${_state.forecasts.length})';
}
