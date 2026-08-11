import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/routes/app_router.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
import 'package:flutter/material.dart';
import 'package:consumo_plus/features/water/application/water_dependencies.dart';

class ConsumoPlusApp extends StatefulWidget {
  const ConsumoPlusApp({
    super.key,
    required this.startupService,
    this.waterDependencies,
  });

  final StartupService startupService;
  final WaterDependencies? waterDependencies;

  @override
  State<ConsumoPlusApp> createState() => _ConsumoPlusAppState();
}

class _ConsumoPlusAppState extends State<ConsumoPlusApp> {
  late final StartupController _startupController;
  late final WaterDependencies _waterDependencies;

  @override
  void initState() {
    super.initState();
    _startupController = StartupController(widget.startupService);
    _waterDependencies =
        widget.waterDependencies ?? WaterDependencies.production();
  }

  @override
  void dispose() {
    _startupController.dispose();
    _waterDependencies.dispose();
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
        createWaterViewModel: _waterDependencies.createViewModel,
      ).onGenerateRoute,
    );
  }
}
