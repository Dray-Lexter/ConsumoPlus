import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/routes/app_router.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/config/demo_providers.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
import 'package:consumo_plus/features/home/home_screen.dart';
import 'package:consumo_plus/features/provider/provider_placeholder_screen.dart';
import 'package:consumo_plus/shared/widgets/utility_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets(
    'electricity rotation applies to the icon but not its container',
    (tester) async {
      await tester.pumpWidget(_home());

      final electricityCard = find.byKey(const Key('providerCard-electrosur'));
      final iconTransform = find.descendant(
        of: electricityCard,
        matching: find.byWidgetPredicate(
          (widget) => widget is Transform && widget.child is Icon,
        ),
      );
      final containerTransform = find.descendant(
        of: electricityCard,
        matching: find.byWidgetPredicate(
          (widget) => widget is Transform && widget.child is Container,
        ),
      );

      expect(iconTransform, findsOneWidget);
      expect(tester.widget<Transform>(iconTransform).child, isA<Icon>());
      expect(containerTransform, findsNothing);

      final expectedTransform = Matrix4.rotationZ(
        electrosurProvider.utilityType.visual.iconRotationRadians,
      );
      expect(
        tester.widget<Transform>(iconTransform).transform.storage,
        orderedEquals(expectedTransform.storage),
      );
    },
  );

  testWidgets('service card semantic action selects its provider', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      ProviderIdentity? selectedProvider;
      await tester.pumpWidget(
        _home(onProviderSelected: (identity) => selectedProvider = identity),
      );

      final waterCard = find.byKey(const Key('providerCard-eps-tacna'));
      final semanticCard = find.bySemanticsLabel('Abrir Agua de EPS Tacna');
      expect(semanticCard, findsOneWidget);
      final node = tester.getSemantics(semanticCard);
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
      await tester.pump();

      expect(selectedProvider, same(epsTacnaProvider));
      expect(tester.getSize(waterCard).height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Home announces the header product name once', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_home());

      final headerNode = tester.semantics.find(find.text(AppMetadata.name));
      final label = headerNode.getSemanticsData().label;
      expect(
        RegExp(RegExp.escape(AppMetadata.name)).allMatches(label),
        hasLength(1),
      );
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

  testWidgets('AppRouter opens both typed providers and returns to Home', (
    tester,
  ) async {
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

    final epsCard = find.byKey(const Key('providerCard-eps-tacna'));
    await tester.ensureVisible(epsCard);
    await tester.tap(epsCard);
    await tester.pumpAndSettle();
    expect(observer.pushedRoutes.last.settings.name, AppRoutes.provider);
    expect(
      observer.pushedRoutes.last.settings.arguments,
      same(epsTacnaProvider),
    );
    expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
    expect(
      tester
          .widget<ProviderPlaceholderScreen>(
            find.byType(ProviderPlaceholderScreen),
          )
          .identity,
      same(epsTacnaProvider),
    );
    expect(find.text('Agua'), findsNWidgets(2));
    expect(find.text('EPS Tacna'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    final electrosurCard = find.byKey(const Key('providerCard-electrosur'));
    await tester.ensureVisible(electrosurCard);
    await tester.tap(electrosurCard);
    await tester.pumpAndSettle();
    expect(observer.pushedRoutes.last.settings.name, AppRoutes.provider);
    expect(
      observer.pushedRoutes.last.settings.arguments,
      same(electrosurProvider),
    );
    expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
    expect(
      tester
          .widget<ProviderPlaceholderScreen>(
            find.byType(ProviderPlaceholderScreen),
          )
          .identity,
      same(electrosurProvider),
    );
    expect(find.text('Electricidad'), findsNWidgets(2));
    expect(find.text('Electrosur'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();
    expect(observer.pushedRoutes.last.settings.name, AppRoutes.settings);
    expect(find.text(AppCopy.routeUnavailable), findsOneWidget);
  });

  testWidgets('AppRouter rejects missing and wrong provider arguments', (
    tester,
  ) async {
    final controller = StartupController(_ImmediateStartupService());
    addTearDown(controller.dispose);
    final router = AppRouter(startupController: controller);

    Widget routeScreen(RouteSettings settings) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            final route =
                router.onGenerateRoute(settings) as MaterialPageRoute<void>;
            return route.buildPage(
              context,
              kAlwaysDismissedAnimation,
              kAlwaysDismissedAnimation,
            );
          },
        ),
      );
    }

    await tester.pumpWidget(
      routeScreen(const RouteSettings(name: AppRoutes.provider)),
    );
    expect(find.text(AppCopy.routeUnavailable), findsOneWidget);
    expect(find.byType(ProviderPlaceholderScreen), findsNothing);

    await tester.pumpWidget(
      routeScreen(
        const RouteSettings(name: AppRoutes.provider, arguments: 'EPS Tacna'),
      ),
    );
    expect(find.text(AppCopy.routeUnavailable), findsOneWidget);
    expect(find.byType(ProviderPlaceholderScreen), findsNothing);
  });
}
