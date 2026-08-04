import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('utility visual identity is centralized and distinct', () {
    final water = UtilityType.water.visual;
    final electricity = UtilityType.electricity.visual;

    expect(water.icon, Icons.water_drop_rounded);
    expect(electricity.icon, Icons.bolt_rounded);
    expect(water.accent, isNot(electricity.accent));
    expect(water.iconRadius, isNot(electricity.iconRadius));
  });

  test('light theme uses Material 3 and centralized canvas color', () {
    final theme = AppTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F6F2));
  });
}
