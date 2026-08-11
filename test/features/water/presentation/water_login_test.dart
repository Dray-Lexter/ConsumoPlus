import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_result.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/domain/repositories/water_repository.dart';
import 'package:consumo_plus/features/water/presentation/water_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements WaterRepository {
  String? rememberedUsername = 'USUARIO-DE-PRUEBA';
  String? receivedPassword;
  var synchronizeCalls = 0;

  @override
  Future<void> deleteWaterData() async {}

  @override
  Future<WaterSnapshot?> loadLocal() async => null;

  @override
  Future<String?> loadRememberedUsername() async => rememberedUsername;

  @override
  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  }) async {
    synchronizeCalls += 1;
    receivedPassword = password;
    throw UnimplementedError('The test only verifies form submission.');
  }
}

Widget _app(_Repository repository) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: WaterScreen(
      createViewModel: () async => WaterViewModel(repository: repository),
    ),
  );
}

void main() {
  testWidgets('HTTP authorization is required and password is cleared', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El portal de EPS Tacna utiliza actualmente una conexión no cifrada.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Evita ingresar desde redes Wi-Fi públicas. ConsumoPlus no almacena tu contraseña.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byKey(const Key('waterUsernameField')), findsOneWidget);
    expect(find.byKey(const Key('waterPasswordField')), findsOneWidget);

    final connect = find.byKey(const Key('waterConnectButton'));
    expect(tester.widget<FilledButton>(connect).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('waterPasswordField')),
      'CLAVE-EFIMERA-DE-PRUEBA',
    );
    await tester.tap(find.byKey(const Key('waterHttpAuthorization')));
    await tester.pump();
    expect(tester.widget<FilledButton>(connect).onPressed, isNotNull);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();

    expect(repository.synchronizeCalls, 1);
    expect(repository.receivedPassword, 'CLAVE-EFIMERA-DE-PRUEBA');
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('waterPasswordField')),
    );
    expect(passwordField.controller?.text, isEmpty);
  });

  testWidgets('password visibility control has an accessible tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repository()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mostrar clave'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar clave'));
    await tester.pump();
    expect(find.byTooltip('Ocultar clave'), findsOneWidget);
  });

  testWidgets('empty Water remains usable at 320px with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: _app(_Repository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('waterConnectButton')),
      240,
    );
    await tester.pump();

    expect(find.byKey(const Key('waterConnectButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
