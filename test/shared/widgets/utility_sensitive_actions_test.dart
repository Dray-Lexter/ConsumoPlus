import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/utility_sensitive_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supply actions share confirmation and destructive hierarchy', (
    tester,
  ) async {
    var changeCalls = 0;
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: UtilitySensitiveActions(
            utilityType: UtilityType.electricity,
            serviceName: 'Electricidad',
            otherServiceName: 'Agua',
            onChangeSupply: () async => changeCalls += 1,
            onDeleteData: () async => deleteCalls += 1,
          ),
        ),
      ),
    );

    expect(find.text('Cambiar de suministro'), findsOneWidget);
    expect(find.text('Eliminar datos de Electricidad'), findsOneWidget);
    expect(find.byType(DestructiveActionButton), findsOneWidget);

    await tester.tap(find.text('Cambiar de suministro'));
    await tester.pumpAndSettle();
    expect(find.text('Cambiar suministro de Electricidad'), findsOneWidget);
    expect(changeCalls, 0);
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    expect(changeCalls, 1);

    await tester.tap(find.text('Eliminar datos de Electricidad'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar datos de Electricidad'), findsNWidgets(2));
    expect(deleteCalls, 0);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Eliminar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);
  });
}
