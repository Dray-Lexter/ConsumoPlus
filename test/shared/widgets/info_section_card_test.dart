import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'information section adapts long values at 320px and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: InfoSectionCard(
                title: 'Resumen ficticio',
                utilityType: UtilityType.electricity,
                rows: [
                  InfoRowData(
                    label: 'Dirección',
                    value: 'AVENIDA FICTICIA EXTENSA NÚMERO 123, TACNA',
                  ),
                  InfoRowData(label: 'Tarifa', value: 'BT5B-FICTICIA'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InfoRow), findsNWidgets(2));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.bolt_rounded)).color,
        AppColors.electricity,
      );
      expect(
        find.text('AVENIDA FICTICIA EXTENSA NÚMERO 123, TACNA'),
        findsOneWidget,
      );
    },
  );
}
