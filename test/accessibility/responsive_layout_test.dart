import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/config/service_providers.dart';
import 'package:consumo_plus/features/home/application/forecast_controller.dart';
import 'package:consumo_plus/features/home/application/forecast_source.dart';
import 'package:consumo_plus/features/home/home_screen.dart';
import 'package:consumo_plus/features/home/application/upcoming_dates_controller.dart';
import 'package:consumo_plus/features/home/application/upcoming_dates_source.dart';
import 'package:consumo_plus/features/home/domain/forecast/service_forecast_calculator.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyUpcomingDatesSource implements UpcomingDatesSource {
  @override
  Future<UpcomingDatesInput> load() async => const UpcomingDatesInput(
    waterConnected: false,
    electricityConnected: false,
  );
}

class _EmptyForecastSource implements ForecastSource {
  @override
  Future<List<ServiceForecastInput>> load() async => const [];
}

void main() {
  testWidgets('Home remains responsive and exposes provider actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: HomeScreen(
            providers: serviceProviders,
            onProviderSelected: (_) {},
            onSettingsSelected: () {},
            createUpcomingDatesController: () async =>
                UpcomingDatesController(source: _EmptyUpcomingDatesSource()),
            createForecastController: () async =>
                ForecastController(source: _EmptyForecastSource()),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('providerCard-eps-tacna')),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.byKey(const Key('providerCard-eps-tacna')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Abrir Agua de EPS Tacna'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('providerCard-electrosur')),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.byKey(const Key('providerCard-electrosur')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Abrir Electricidad de Electrosur'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}
