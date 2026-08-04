import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/settings/settings_screen.dart';
import 'package:consumo_plus/shared/widgets/settings_info_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _settings({TextScaler? textScaler}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: const SettingsScreen(),
  );
}

void main() {
  testWidgets('Settings presents static product information', (tester) async {
    await tester.pumpWidget(_settings());

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Disponible en una versión posterior'), findsOneWidget);
    expect(find.text('Privacidad y almacenamiento local'), findsOneWidget);
    expect(find.text('Versión 0.1.0'), findsOneWidget);
    expect(find.byType(SettingsInfoRow), findsNWidgets(2));
    expect(find.byKey(const Key('settingsContent')), findsOneWidget);
  });

  testWidgets('Settings contains no misleading interactive controls', (
    tester,
  ) async {
    await tester.pumpWidget(_settings());

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('Settings remains scrollable with narrow large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _settings(textScaler: const TextScaler.linear(1.8)),
    );

    await tester.scrollUntilVisible(
      find.text('Versión 0.1.0'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Versión 0.1.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
