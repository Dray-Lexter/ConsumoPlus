import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('service context applies its accent to interactive controls', (
    tester,
  ) async {
    Future<Color> primaryFor(UtilityType utilityType) async {
      Color? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: UtilityTheme(
            utilityType: utilityType,
            child: Builder(
              builder: (context) {
                captured = Theme.of(context).colorScheme.primary;
                return const Scaffold(
                  body: Column(
                    children: [
                      FilledButton(onPressed: null, child: Text('Actualizar')),
                      Checkbox(value: true, onChanged: null),
                      CircularProgressIndicator(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      return captured!;
    }

    expect(await primaryFor(UtilityType.water), AppColors.water);
    expect(await primaryFor(UtilityType.electricity), AppColors.electricity);
  });
}
