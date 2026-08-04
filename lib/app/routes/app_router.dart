import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/features/home/home_screen.dart';
import 'package:consumo_plus/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter({required this.startupController});

  final StartupController startupController;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.splash => SplashScreen(controller: startupController),
      AppRoutes.home => const HomeScreen(),
      _ => const _UnknownRouteScreen(),
    };

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text(AppCopy.routeUnavailable)));
  }
}
