import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/application/forecast_controller.dart';
import 'package:consumo_plus/features/home/application/forecast_source.dart';
import 'package:consumo_plus/features/home/domain/forecast/forecast_models.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForecastSource implements ForecastSource {
  _FakeForecastSource(this.inputs);

  List<ServiceForecastInput> inputs;
  Object? error;
  var loadCount = 0;

  @override
  Future<List<ServiceForecastInput>> load() async {
    loadCount += 1;
    final failure = error;
    if (failure != null) throw failure;
    return inputs;
  }
}

void main() {
  test('refresh calculates typed forecasts from local inputs', () async {
    final source = _FakeForecastSource([_waterInput(6)]);
    final controller = ForecastController(source: source);
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.forecasts, hasLength(1));
    expect(
      controller.state.forecasts.single.status,
      ForecastStatus.preliminary,
    );
    expect(source.loadCount, 1);
  });

  test('a local failure clears forecasts without exposing the error', () async {
    final source = _FakeForecastSource([_waterInput(6)]);
    final controller = ForecastController(source: source);
    addTearDown(controller.dispose);
    await controller.refresh();
    source.error = StateError('private local details');

    await controller.refresh();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.forecasts, isEmpty);
    expect(controller.toString(), isNot(contains('private local details')));
  });

  test('each refresh reevaluates newly available monthly history', () async {
    final source = _FakeForecastSource([_waterInput(6)]);
    final controller = ForecastController(source: source);
    addTearDown(controller.dispose);
    await controller.refresh();
    source.inputs = [_waterInput(7)];

    await controller.refresh();

    expect(controller.state.forecasts.single.sampleCount, 7);
    expect(source.loadCount, 2);
  });
}

ServiceForecastInput _waterInput(int count) => ServiceForecastInput(
  utilityType: UtilityType.water,
  serviceName: 'Agua',
  providerName: 'EPS Tacna',
  consumptionUnit: 'm³',
  observations: [
    for (var index = 0; index < count; index++)
      MonthlyUtilityObservation(
        period: MonthPeriod(2026, index + 1),
        consumption: 10 + index.toDouble(),
        monthlyCostCents: 3000 + index * 100,
        synchronizedAt: DateTime.utc(2026, 8, index + 1),
        sourceKey: 'W-$index',
      ),
  ],
);
