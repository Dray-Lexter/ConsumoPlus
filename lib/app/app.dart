import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/app_dependencies.dart';
import 'package:consumo_plus/app/routes/app_router.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
import 'package:flutter/material.dart';

class ConsumoPlusApp extends StatefulWidget {
  const ConsumoPlusApp({
    super.key,
    required this.startupService,
    this.dependencies,
  });

  final StartupService startupService;
  final AppDependencies? dependencies;

  @override
  State<ConsumoPlusApp> createState() => _ConsumoPlusAppState();
}

class _ConsumoPlusAppState extends State<ConsumoPlusApp> {
  late final StartupController _startupController;
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _startupController = StartupController(widget.startupService);
    _dependencies = widget.dependencies ?? AppDependencies.production();
  }

  @override
  void dispose() {
    _startupController.dispose();
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppMetadata.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter(
        startupController: _startupController,
        createUpcomingDatesController:
            _dependencies.createUpcomingDatesController,
        createForecastController: _dependencies.createForecastController,
        createWaterViewModel: _dependencies.createWaterViewModel,
        createElectricityViewModel: _dependencies.createElectricityViewModel,
      ).onGenerateRoute,
    );
  }
}
