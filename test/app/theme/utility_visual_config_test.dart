import 'package:consumo_plus/app/theme/app_colors.dart';
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

  test('utility accents meet AA contrast on surfaces and containers', () {
    final utilities = [
      (name: 'water', visual: UtilityType.water.visual),
      (name: 'electricity', visual: UtilityType.electricity.visual),
    ];

    for (final utility in utilities) {
      expect(
        _contrastRatio(utility.visual.accent, AppColors.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${utility.name} accent on surface',
      );
      expect(
        _contrastRatio(utility.visual.accent, utility.visual.container),
        greaterThanOrEqualTo(4.5),
        reason: '${utility.name} accent on its container',
      );
    }
  });

  test('light theme uses Material 3 and centralized canvas color', () {
    final theme = AppTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F6F2));
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
