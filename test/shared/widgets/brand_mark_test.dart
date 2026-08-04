import 'package:consumo_plus/app/theme/app_colors.dart';
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

    final waterFinder = find.byIcon(Icons.water_drop_rounded);
    final electricityFinder = find.byIcon(Icons.bolt_rounded);

    expect(waterFinder, findsOneWidget);
    expect(electricityFinder, findsOneWidget);
    expect(tester.widget<Icon>(waterFinder).color, AppColors.water);
    expect(tester.widget<Icon>(electricityFinder).color, AppColors.electricity);
  });
}
