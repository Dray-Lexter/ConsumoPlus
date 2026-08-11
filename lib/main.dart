import 'package:consumo_plus/app/app.dart';
import 'package:consumo_plus/core/config/startup_config.dart';
import 'package:consumo_plus/core/startup/delayed_startup_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    ConsumoPlusApp(
      startupService: DelayedStartupService(StartupConfig.startupDelay),
    ),
  );
}
