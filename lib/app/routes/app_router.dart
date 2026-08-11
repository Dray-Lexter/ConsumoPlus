import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/core/config/demo_providers.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/features/home/home_screen.dart';
import 'package:consumo_plus/features/provider/provider_placeholder_screen.dart';
import 'package:consumo_plus/features/settings/settings_screen.dart';
import 'package:consumo_plus/features/splash/splash_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_screen.dart';
import 'package:consumo_plus/features/water/presentation/water_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter({
    required this.startupController,
    this.createWaterViewModel,
    this.createElectricityViewModel,
  });

  final StartupController startupController;
  final WaterViewModelFactory? createWaterViewModel;
  final ElectricityViewModelFactory? createElectricityViewModel;

  static Future<Never> _missingWaterDependencies() {
    throw StateError('Water dependencies are not configured.');
  }

  static Future<Never> _missingElectricityDependencies() {
    throw StateError('Electricity dependencies are not configured.');
  }

  Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => switch (settings.name) {
        AppRoutes.splash => SplashScreen(controller: startupController),
        AppRoutes.home => HomeScreen(
          providers: demoProviders,
          onProviderSelected: (identity) {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.provider, arguments: identity);
          },
          onSettingsSelected: () {
            Navigator.of(context).pushNamed(AppRoutes.settings);
          },
        ),
        AppRoutes.settings => const SettingsScreen(),
        AppRoutes.provider => switch (settings.arguments) {
          ProviderIdentity identity when identity.id == epsTacnaProvider.id =>
            WaterScreen(
              createViewModel:
                  createWaterViewModel ?? _missingWaterDependencies,
            ),
          ProviderIdentity identity when identity.id == electrosurProvider.id =>
            ElectricityScreen(
              createViewModel:
                  createElectricityViewModel ?? _missingElectricityDependencies,
            ),
          ProviderIdentity identity => ProviderPlaceholderScreen(
            identity: identity,
          ),
          _ => const _UnknownRouteScreen(),
        },
        _ => const _UnknownRouteScreen(),
      },
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text(AppCopy.routeUnavailable)));
  }
}
