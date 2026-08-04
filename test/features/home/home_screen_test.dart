import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/routes/app_router.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/config/demo_providers.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
import 'package:consumo_plus/features/home/home_screen.dart';
import 'package:consumo_plus/shared/widgets/utility_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ImmediateStartupService implements StartupService {
  @override
  Future<void> initialize() async {}
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

Widget _home({
  ValueChanged<ProviderIdentity>? onProviderSelected,
  VoidCallback? onSettingsSelected,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: HomeScreen(
      providers: demoProviders,
      onProviderSelected: onProviderSelected ?? (_) {},
      onSettingsSelected: onSettingsSelected ?? () {},
    ),
  );
}

void main() {
  testWidgets('Home presents the domestic introduction and provider choices', (
    tester,
  ) async {
    await tester.pumpWidget(_home());

    expect(find.text(AppCopy.welcomeTitle), findsOneWidget);
    expect(find.text(AppCopy.homeTitle), findsOneWidget);
    expect(find.text(AppCopy.demoNotice), findsOneWidget);
    expect(find.text('EPS Tacna'), findsOneWidget);
    expect(find.text('Electrosur'), findsOneWidget);
    expect(find.byType(UtilityServiceCard), findsNWidgets(2));

    final settingsButton = tester.widget<IconButton>(
      find.byKey(const Key('openSettingsButton')),
    );
    expect(settingsButton.tooltip, AppCopy.settingsTooltip);
  });

  testWidgets('Home forwards provider and settings selections', (tester) async {
    ProviderIdentity? selectedProvider;
    var settingsCalls = 0;

    await tester.pumpWidget(
      _home(
        onProviderSelected: (identity) => selectedProvider = identity,
        onSettingsSelected: () => settingsCalls += 1,
      ),
    );

    await tester.tap(find.byKey(const Key('providerCard-eps-tacna')));
    expect(selectedProvider, same(epsTacnaProvider));

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    expect(settingsCalls, 1);
  });

  testWidgets('service cards use distinct centralized utility icons', (
    tester,
  ) async {
    await tester.pumpWidget(_home());

    final waterCard = find.byKey(const Key('providerCard-eps-tacna'));
    final electricityCard = find.byKey(const Key('providerCard-electrosur'));

    expect(
      find.descendant(
        of: waterCard,
        matching: find.byIcon(Icons.water_drop_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: electricityCard,
        matching: find.byIcon(Icons.bolt_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('service cards expose one clear button action and tap target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_home());

      final waterCard = find.byKey(const Key('providerCard-eps-tacna'));
      expect(find.bySemanticsLabel('Abrir Agua de EPS Tacna'), findsOneWidget);
      expect(tester.getSize(waterCard).height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Home remains scrollable on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_home(textScaler: const TextScaler.linear(1.8)));
    await tester.scrollUntilVisible(
      find.byKey(const Key('providerCard-electrosur')),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byKey(const Key('providerCard-electrosur')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AppRouter supplies native provider and settings route callbacks',
    (tester) async {
      final observer = _RecordingNavigatorObserver();
      final controller = StartupController(_ImmediateStartupService());
      addTearDown(controller.dispose);
      final router = AppRouter(startupController: controller);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          navigatorObservers: [observer],
          onGenerateRoute: router.onGenerateRoute,
          home: Builder(
            builder: (context) {
              final homeRoute =
                  router.onGenerateRoute(
                        const RouteSettings(name: AppRoutes.home),
                      )
                      as MaterialPageRoute<void>;
              return homeRoute.buildPage(
                context,
                kAlwaysDismissedAnimation,
                kAlwaysDismissedAnimation,
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('providerCard-eps-tacna')));
      await tester.pumpAndSettle();
      expect(observer.pushedRoutes.last.settings.name, AppRoutes.provider);
      expect(
        observer.pushedRoutes.last.settings.arguments,
        same(epsTacnaProvider),
      );

      Navigator.of(tester.element(find.text(AppCopy.routeUnavailable))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();
      expect(observer.pushedRoutes.last.settings.name, AppRoutes.settings);
    },
  );
}
