import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BrandMark combines water and electricity identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandMark())),
    );

    final waterVisual = UtilityType.water.visual;
    final electricityVisual = UtilityType.electricity.visual;
    final waterFinder = find.byIcon(waterVisual.icon);
    final electricityFinder = find.byIcon(electricityVisual.icon);

    expect(waterFinder, findsOneWidget);
    expect(electricityFinder, findsOneWidget);
    expect(tester.widget<Icon>(waterFinder).color, waterVisual.accent);
    expect(
      tester.widget<Icon>(electricityFinder).color,
      electricityVisual.accent,
    );
  });
}
