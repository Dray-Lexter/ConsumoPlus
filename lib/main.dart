import 'package:consumo_plus/app/app.dart';
import 'package:consumo_plus/core/config/demo_config.dart';
import 'package:consumo_plus/core/startup/demo_startup_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    ConsumoPlusApp(startupService: DemoStartupService(DemoConfig.startupDelay)),
  );
}
