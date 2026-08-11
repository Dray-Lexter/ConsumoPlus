import 'dart:io';

import 'package:consumo_plus/features/water/data/remote/eps_tacna_endpoints.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_http_client.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_remote_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_transport.dart';
import 'package:consumo_plus/features/water/data/remote/in_memory_cookie_jar.dart';
import 'package:consumo_plus/features/water/data/remote/portal_request.dart';
import 'package:consumo_plus/features/water/data/remote/portal_response.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixture_reader.dart';

class _FakeTransport implements EpsTacnaTransport {
  _FakeTransport(this.results);

  final List<Object> results;
  final requests = <PortalRequest>[];
  var closed = false;

  @override
  Future<PortalResponse> send(PortalRequest request) async {
    requests.add(request);
    final result = results.removeAt(0);
    if (result is Exception) throw result;
    return result as PortalResponse;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

PortalResponse response(String path, String body) {
  return PortalResponse(
    statusCode: 200,
    uri: EpsTacnaEndpoints.base.resolve(path),
    body: body,
  );
}

void main() {
  test('endpoints match the inspected portal and reject other hosts', () {
    expect(EpsTacnaEndpoints.login.path, '/src/controlador/login.php');
    expect(EpsTacnaEndpoints.billing.path, '/src/controlador/ctacte.php');
    expect(
      EpsTacnaEndpoints.payments.path,
      '/src/controlador/historialpagos.php',
    );
    expect(EpsTacnaEndpoints.logout.path, '/src/controlador/salir.php');
    expect(EpsTacnaEndpoints.isAllowed(EpsTacnaEndpoints.billing), isTrue);
    expect(
      EpsTacnaEndpoints.isAllowed(Uri.parse('http://example.com/')),
      isFalse,
    );
    expect(
      EpsTacnaEndpoints.isAllowed(
        Uri.parse('https://oficinavirtual.epstacna.com.pe/'),
      ),
      isFalse,
    );
  });

  test('cookie jar keeps values in memory without exposing them', () {
    final jar = InMemoryCookieJar();
    final cookie = Cookie('SESSION_TEST', 'sensitive-test-value')
      ..path = '/'
      ..httpOnly = true;

    jar.store(EpsTacnaEndpoints.base, [cookie]);

    expect(jar.cookiesFor(EpsTacnaEndpoints.billing), hasLength(1));
    expect(jar.toString(), isNot(contains('sensitive-test-value')));
    jar.clear();
    expect(jar.isEmpty, isTrue);
  });

  test(
    'remote source authenticates, downloads every module and closes',
    () async {
      final transport = _FakeTransport([
        response(
          'src/controlador/main.php',
          fixture('eps_tacna/authenticated_shell.html'),
        ),
        response(
          'src/controlador/ctacte.php',
          fixture('eps_tacna/billing_history.html'),
        ),
        response(
          'src/controlador/historialpagos.php',
          fixture('eps_tacna/payment_history.html'),
        ),
        response('src/vista/v_login.php', fixture('eps_tacna/login_form.html')),
      ]);
      final source = EpsTacnaRemoteDataSource(
        clientFactory: () => EpsTacnaHttpClient(transport),
      );

      final data = await source.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
        synchronizedAt: DateTime.utc(2026, 8, 4, 12),
      );

      expect(data.account.customerCode, '123456');
      expect(data.account.ownerName, 'PERSONA DE PRUEBA');
      expect(data.account.serviceAddress, 'AV. EJEMPLO 123');
      expect(data.account.serviceStatus, 'OPERATIVO');
      expect(data.account.tariffName, 'DOMESTICA');
      expect(data.account.meterNumber, 'MEDIDOR123');
      expect(data.account.connectionType, 'AGUA');
      expect(data.billingRecords, hasLength(3));
      expect(data.paymentRecords, hasLength(2));
      expect(
        data.billingRecords.every(
          (record) => record.customerCode == data.account.customerCode,
        ),
        isTrue,
      );
      expect(
        data.paymentRecords.every(
          (record) => record.customerCode == data.account.customerCode,
        ),
        isTrue,
      );
      expect(transport.closed, isTrue);
      expect(
        transport.requests.map(
          (request) => '${request.method} ${request.uri.path}',
        ),
        [
          'POST /src/controlador/login.php',
          'POST /src/controlador/ctacte.php',
          'POST /src/controlador/historialpagos.php',
          'GET /src/controlador/salir.php',
        ],
      );
      expect(transport.requests.first.formFields.keys, {'usu', 'pas'});
      expect(
        transport.requests.first.toString(),
        isNot(contains('CLAVE-EFIMERA-DE-PRUEBA')),
      );
    },
  );

  test(
    'missing optional supply data still completes synchronization',
    () async {
      final transport = _FakeTransport([
        response(
          'src/controlador/main.php',
          fixture('eps_tacna/authenticated_shell.html'),
        ),
        response(
          'src/controlador/ctacte.php',
          fixture('eps_tacna/billing_history_partial.html'),
        ),
        response(
          'src/controlador/historialpagos.php',
          fixture('eps_tacna/payment_history.html'),
        ),
        response('src/vista/v_login.php', fixture('eps_tacna/login_form.html')),
      ]);
      final source = EpsTacnaRemoteDataSource(
        clientFactory: () => EpsTacnaHttpClient(transport),
      );

      final data = await source.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
        synchronizedAt: DateTime.utc(2026, 8, 4, 12),
      );

      expect(data.account.connectionType, isNull);
      expect(data.billingRecords, hasLength(1));
      expect(data.paymentRecords, hasLength(2));
    },
  );

  test(
    'accepted login followed by invalid billing is not credentials',
    () async {
      final transport = _FakeTransport([
        response(
          'src/controlador/main.php',
          fixture('eps_tacna/authenticated_shell.html'),
        ),
        response(
          'src/controlador/ctacte.php',
          fixture('eps_tacna/missing_headers.html'),
        ),
        response('src/vista/v_login.php', fixture('eps_tacna/login_form.html')),
      ]);
      final source = EpsTacnaRemoteDataSource(
        clientFactory: () => EpsTacnaHttpClient(transport),
      );

      await expectLater(
        source.synchronize(
          username: 'CLIENTE-DE-PRUEBA',
          password: 'CLAVE-EFIMERA-DE-PRUEBA',
          synchronizedAt: DateTime.utc(2026, 8, 4),
        ),
        throwsA(
          allOf(
            isA<BillingHistoryStructureException>(),
            isNot(isA<InvalidCredentialsException>()),
          ),
        ),
      );
    },
  );

  test(
    'accepted login distinguishes an incompatible payment history',
    () async {
      final transport = _FakeTransport([
        response(
          'src/controlador/main.php',
          fixture('eps_tacna/authenticated_shell.html'),
        ),
        response(
          'src/controlador/ctacte.php',
          fixture('eps_tacna/billing_history.html'),
        ),
        response(
          'src/controlador/historialpagos.php',
          fixture('eps_tacna/missing_headers.html'),
        ),
        response('src/vista/v_login.php', fixture('eps_tacna/login_form.html')),
      ]);
      final source = EpsTacnaRemoteDataSource(
        clientFactory: () => EpsTacnaHttpClient(transport),
      );

      await expectLater(
        source.synchronize(
          username: 'CLIENTE-DE-PRUEBA',
          password: 'CLAVE-EFIMERA-DE-PRUEBA',
          synchronizedAt: DateTime.utc(2026, 8, 4),
        ),
        throwsA(isA<PaymentHistoryStructureException>()),
      );
    },
  );

  test(
    'login without authenticated signal is a sanitized invalid error',
    () async {
      const echoedSecret = 'NO-DEBE-APARECER';
      final transport = _FakeTransport([
        response('src/controlador/login.php', 'ERROR SQL $echoedSecret'),
      ]);
      final source = EpsTacnaRemoteDataSource(
        clientFactory: () => EpsTacnaHttpClient(transport),
      );

      Object? thrown;
      try {
        await source.synchronize(
          username: 'USUARIO-FALSO',
          password: echoedSecret,
          synchronizedAt: DateTime.utc(2026, 8, 4),
        );
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isA<InvalidCredentialsException>());
      expect(thrown.toString(), isNot(contains(echoedSecret)));
      expect(transport.closed, isTrue);
    },
  );

  test('login form returned by billing is a session expiration', () async {
    final transport = _FakeTransport([
      response(
        'src/controlador/main.php',
        fixture('eps_tacna/authenticated_shell.html'),
      ),
      response(
        'src/controlador/ctacte.php',
        fixture('eps_tacna/login_form.html'),
      ),
      response('src/vista/v_login.php', fixture('eps_tacna/login_form.html')),
    ]);
    final source = EpsTacnaRemoteDataSource(
      clientFactory: () => EpsTacnaHttpClient(transport),
    );

    expect(
      () => source.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
        synchronizedAt: DateTime.utc(2026, 8, 4),
      ),
      throwsA(isA<SessionExpiredException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(transport.closed, isTrue);
  });

  test('transport failures stay typed and always close the session', () async {
    final transport = _FakeTransport([const NetworkTimeoutException()]);
    final source = EpsTacnaRemoteDataSource(
      clientFactory: () => EpsTacnaHttpClient(transport),
    );

    expect(
      () => source.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
        synchronizedAt: DateTime.utc(2026, 8, 4),
      ),
      throwsA(isA<NetworkTimeoutException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(transport.closed, isTrue);
  });
}
