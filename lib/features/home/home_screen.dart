import 'dart:async';

import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/features/home/application/forecast_controller.dart';
import 'package:consumo_plus/features/home/application/upcoming_dates_controller.dart';
import 'package:consumo_plus/features/home/presentation/widgets/forecast_section.dart';
import 'package:consumo_plus/features/home/presentation/widgets/upcoming_dates_section.dart';
import 'package:consumo_plus/shared/widgets/brand_mark.dart';
import 'package:consumo_plus/shared/widgets/utility_service_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.providers,
    required this.onProviderSelected,
    required this.onSettingsSelected,
    required this.createUpcomingDatesController,
    required this.createForecastController,
    super.key,
  });

  final List<ProviderIdentity> providers;
  final FutureOr<void> Function(ProviderIdentity) onProviderSelected;
  final FutureOr<void> Function() onSettingsSelected;
  final UpcomingDatesControllerFactory createUpcomingDatesController;
  final ForecastControllerFactory createForecastController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  UpcomingDatesController? _upcomingDatesController;
  ForecastController? _forecastController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareUpcomingDates();
    _prepareForecasts();
  }

  Future<void> _prepareForecasts() async {
    try {
      final controller = await widget.createForecastController();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _forecastController = controller;
      controller.addListener(_onForecastChanged);
      await controller.refresh();
    } on Object {
      // Forecasts are supplementary and never block the main Home view.
    }
  }

  Future<void> _prepareUpcomingDates() async {
    try {
      final controller = await widget.createUpcomingDatesController();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _upcomingDatesController = controller;
      controller.addListener(_onUpcomingDatesChanged);
      await controller.refresh();
    } on Object {
      // Upcoming dates are supplementary and never block the main Home view.
    }
  }

  void _onUpcomingDatesChanged() {
    if (mounted) setState(() {});
  }

  void _onForecastChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshSupplementaryData() async {
    await Future.wait<void>([
      if (_upcomingDatesController case final controller?) controller.refresh(),
      if (_forecastController case final controller?) controller.refresh(),
    ]);
  }

  Future<void> _openProvider(ProviderIdentity provider) async {
    await Future<void>.sync(() => widget.onProviderSelected(provider));
    if (mounted) await _refreshSupplementaryData();
  }

  Future<void> _openSettings() async {
    await Future<void>.sync(widget.onSettingsSelected);
    if (mounted) await _refreshSupplementaryData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSupplementaryData());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _upcomingDatesController;
    if (controller != null) {
      controller.removeListener(_onUpcomingDatesChanged);
      controller.dispose();
    }
    final forecastController = _forecastController;
    if (forecastController != null) {
      forecastController.removeListener(_onForecastChanged);
      forecastController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final schedules = _upcomingDatesController?.state.schedules;
    final forecasts = _forecastController?.state.forecasts;

    return Scaffold(
      key: const Key('homeScreen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                const ExcludeSemantics(child: BrandMark(size: AppSpacing.xxl)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(AppMetadata.name, style: textTheme.titleMedium),
                ),
                IconButton(
                  key: const Key('openSettingsButton'),
                  onPressed: _openSettings,
                  tooltip: AppCopy.settingsTooltip,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppCopy.welcomeTitle,
              style: textTheme.titleMedium?.copyWith(color: AppColors.mutedInk),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(AppCopy.homeTitle, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.mutedInk,
                    size: AppSpacing.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppCopy.localFirstNotice,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                ),
              ],
            ),
            for (final provider in widget.providers) ...[
              const SizedBox(height: AppSpacing.md),
              UtilityServiceCard(
                identity: provider,
                onTap: () => _openProvider(provider),
              ),
            ],
            if (schedules != null && schedules.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              UpcomingDatesSection(schedules: schedules),
            ],
            if (forecasts != null && forecasts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              ForecastSection(forecasts: forecasts),
            ],
          ],
        ),
      ),
    );
  }
}
