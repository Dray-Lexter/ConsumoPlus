import 'dart:async';

import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_durations.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/shared/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final StartupController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasEntered = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback(_afterFirstFrame);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _afterFirstFrame(Duration _) {
    if (!mounted) return;
    setState(() => _hasEntered = true);
    unawaited(widget.controller.initialize());
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});

    if (widget.controller.status != StartupStatus.success || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entranceDuration = reduceMotion
        ? Duration.zero
        : AppDurations.entrance;

    return Scaffold(
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _hasEntered ? 1 : 0,
          duration: entranceDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: _hasEntered ? Offset.zero : const Offset(0, 0.035),
            duration: entranceDuration,
            curve: Curves.easeOutCubic,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _SplashContent(controller: widget.controller),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.controller});

  final StartupController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppMetadata.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppCopy.splashTagline,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (controller.status == StartupStatus.failure)
          _StartupFailure(controller: controller)
        else
          const SizedBox.square(
            dimension: AppSpacing.lg,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
      ],
    );
  }
}

class _StartupFailure extends StatelessWidget {
  const _StartupFailure({required this.controller});

  final StartupController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('startupError'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 32,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppCopy.startupErrorTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppCopy.startupErrorMessage,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('retryStartupButton'),
          onPressed: () => unawaited(controller.retry()),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.xxl),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: const Text(AppCopy.retryAction),
        ),
      ],
    );
  }
}
