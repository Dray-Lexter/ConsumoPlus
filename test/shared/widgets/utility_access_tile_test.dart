import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/utility_access_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('access tiles share neutral surfaces and service accents', (
    tester,
  ) async {
    var waterTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              UtilityAccessTile(
                key: const Key('waterAccess'),
                utilityType: UtilityType.water,
                icon: Icons.receipt_long_outlined,
                title: 'Historial de recibos',
                subtitle: '2 guardados',
                onTap: () => waterTaps += 1,
              ),
              UtilityAccessTile(
                key: const Key('electricityAccess'),
                utilityType: UtilityType.electricity,
                icon: Icons.insights_outlined,
                title: 'Consumos',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsNWidgets(2));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.receipt_long_outlined)).color,
      AppColors.water,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.insights_outlined)).color,
      AppColors.electricity,
    );
    await tester.tap(find.byKey(const Key('waterAccess')));
    expect(waterTaps, 1);
  });
}
