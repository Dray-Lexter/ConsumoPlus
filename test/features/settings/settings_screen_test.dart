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
  testWidgets('Settings presents truthful beta privacy information', (
    tester,
  ) async {
    await tester.pumpWidget(_settings());

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Privacidad y almacenamiento local'), findsOneWidget);
    expect(
      find.text(
        'Tus datos locales se guardan cifrados en este dispositivo. '
        'ConsumoPlus no usa una nube propia para almacenar tu historial.',
      ),
      findsOneWidget,
    );
    expect(find.text('Contraseñas y sesiones'), findsOneWidget);
    expect(
      find.text(
        'Las contraseñas de EPS Tacna y Electrosur no se almacenan. '
        'Las cookies de sesión se mantienen solo durante cada sincronización.',
      ),
      findsOneWidget,
    );
    expect(find.text('Conexiones con proveedores'), findsOneWidget);
    expect(
      find.text(
        'Las conexiones dependen de las condiciones de seguridad de cada '
        'proveedor. EPS Tacna y Electrosur usan actualmente HTTP y requieren '
        'tu autorización explícita.',
      ),
      findsOneWidget,
    );
    expect(find.text('Control de tus datos'), findsOneWidget);
    expect(
      find.text(
        'Puedes eliminar los datos locales de Agua o Electricidad desde el '
        'módulo correspondiente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Apariencia'), findsNothing);
    expect(find.text('Disponible en una versión posterior'), findsNothing);
    expect(find.byType(SettingsInfoRow), findsNWidgets(4));
    expect(find.byKey(const Key('settingsContent')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Versión 0.2.0 Beta'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();
    expect(find.text('Versión 0.2.0 Beta'), findsOneWidget);
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
      find.text('Versión 0.2.0 Beta'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Versión 0.2.0 Beta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
