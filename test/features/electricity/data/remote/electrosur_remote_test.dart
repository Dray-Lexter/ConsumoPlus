import 'dart:io';

import 'package:consumo_plus/features/electricity/data/remote/electrosur_endpoints.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_http_client.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_remote_data_source.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_request.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_response.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_transport.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) =>
    File('test/fixtures/electrosur/$name').readAsStringSync();

class _FakeTransport implements ElectrosurTransport {
  _FakeTransport(this.results);

  final List<Object> results;
  final requests = <ElectrosurRequest>[];
  var closed = false;

  @override
  Future<ElectrosurResponse> send(ElectrosurRequest request) async {
    requests.add(request);
    final result = results.removeAt(0);
    if (result is Exception) throw result;
    return result as ElectrosurResponse;
  }

  @override
  Future<void> close() async => closed = true;
}

ElectrosurResponse response(
  String path,
  String body, {
  int status = 200,
  String? location,
  Set<String> cookieNames = const {},
}) => ElectrosurResponse(
  statusCode: status,
  uri: ElectrosurEndpoints.base.resolve(path),
  body: body,
  location: location,
  cookieNames: cookieNames,
);

void main() {
  test('endpoints use exact observed HTTP www host and port', () {
    expect(
      ElectrosurEndpoints.base.toString(),
      'http://www.electrosur.com.pe:81/',
    );
    expect(ElectrosurEndpoints.login.path, '/Login');
    expect(ElectrosurEndpoints.isAllowed(ElectrosurEndpoints.payments), isTrue);
    expect(
      ElectrosurEndpoints.isAllowed(
        Uri.parse('http://electrosur.com.pe:81/Pagos'),
      ),
      isFalse,
    );
    expect(
      ElectrosurEndpoints.isAllowed(
        Uri.parse('https://www.electrosur.com.pe/Pagos'),
      ),
      isFalse,
    );
  });

  test(
    'login sends exact fields and requires 302, root and ASPXAUTH',
    () async {
      final transport = _FakeTransport([
        response(
          'Login',
          '',
          status: 302,
          location: '/',
          cookieNames: const {'.ASPXAUTH'},
        ),
        response('', fixture('authenticated_home.html')),
      ]);
      final client = ElectrosurHttpClient(transport);

      await client.login(
        contractNumber: 'CONTRATO-FICTICIO-001',
        password: 'CLAVE-EFIMERA-FICTICIA',
      );

      expect(
        transport.requests.map(
          (request) => '${request.method} ${request.uri.path}',
        ),
        ['POST /Login', 'GET /'],
      );
      expect(transport.requests.first.formFields.keys, {
        'GstrNumeroContrato',
        'GstrClave',
      });
      expect(
        transport.requests.first.toString(),
        isNot(contains('CLAVE-EFIMERA-FICTICIA')),
      );
    },
  );

  test(
    'absence of ASPXAUTH is invalid credentials without a guessed message',
    () async {
      final transport = _FakeTransport([
        response(
          'Login',
          fixture('login_form.html'),
          status: 302,
          location: '/',
        ),
      ]);
      final client = ElectrosurHttpClient(transport);

      await expectLater(
        client.login(
          contractNumber: 'CONTRATO-FICTICIO',
          password: 'SECRETO-FICTICIO',
        ),
        throwsA(isA<ElectricityInvalidCredentialsException>()),
      );
    },
  );

  test('returning the login form after 302 is invalid credentials', () async {
    final transport = _FakeTransport([
      response(
        'Login',
        '',
        status: 302,
        location: '/',
        cookieNames: const {'.ASPXAUTH'},
      ),
      response('Login', fixture('login_form.html')),
    ]);
    final client = ElectrosurHttpClient(transport);

    await expectLater(
      client.login(
        contractNumber: 'CONTRATO-FICTICIO',
        password: 'SECRETO-FICTICIO',
      ),
      throwsA(isA<ElectricityInvalidCredentialsException>()),
    );
  });

  test(
    'remote source downloads each page in order and always closes',
    () async {
      final transport = _FakeTransport([
        response(
          'Login',
          '',
          status: 302,
          location: '/',
          cookieNames: const {'.ASPXAUTH'},
        ),
        response('', fixture('authenticated_home.html')),
        response('EstadoCuenta', fixture('account_status.html')),
        response('Consumos', fixture('consumptions.html')),
        response('Pagos', fixture('payments.html')),
        response('Suministro', fixture('supply.html')),
      ]);
      final source = ElectrosurRemoteDataSource(
        clientFactory: () => ElectrosurHttpClient(transport),
      );

      final data = await source.synchronize(
        contractNumber: 'CONTRATO-FICTICIO-001',
        password: 'CLAVE-EFIMERA-FICTICIA',
        synchronizedAt: DateTime.utc(2026, 8, 11, 14),
      );

      expect(data.account.meterNumber, 'MEDIDOR123');
      expect(data.accountStatus.sourcePeriodCode, '202608');
      expect(data.consumptionRecords, hasLength(3));
      expect(data.paymentRecords, hasLength(2));
      expect(data.supplyDetailsAvailable, isTrue);
      expect(transport.closed, isTrue);
      expect(transport.requests.map((request) => request.uri.path), [
        '/Login',
        '/',
        '/EstadoCuenta',
        '/Consumos',
        '/Pagos',
        '/Suministro',
      ]);
    },
  );

  test(
    'redirect to Login after authentication is session expiration',
    () async {
      final transport = _FakeTransport([
        response(
          'Login',
          '',
          status: 302,
          location: '/',
          cookieNames: const {'.ASPXAUTH'},
        ),
        response('', fixture('authenticated_home.html')),
        response('EstadoCuenta', '', status: 302, location: '/Login'),
      ]);
      final source = ElectrosurRemoteDataSource(
        clientFactory: () => ElectrosurHttpClient(transport),
      );

      await expectLater(
        source.synchronize(
          contractNumber: 'CONTRATO-FICTICIO',
          password: 'CLAVE-EFIMERA-FICTICIA',
          synchronizedAt: DateTime.utc(2026, 8, 11),
        ),
        throwsA(isA<ElectricitySessionExpiredException>()),
      );
      expect(transport.closed, isTrue);
    },
  );

  test(
    'an optional Suministro structure failure does not discard core sections',
    () async {
      final transport = _FakeTransport([
        response(
          'Login',
          '',
          status: 302,
          location: '/',
          cookieNames: const {'.ASPXAUTH'},
        ),
        response('', fixture('authenticated_home.html')),
        response('EstadoCuenta', fixture('account_status.html')),
        response('Consumos', fixture('consumptions.html')),
        response('Pagos', fixture('payments.html')),
        response(
          'Suministro',
          '<html><body>contenido irreconocible</body></html>',
        ),
      ]);
      final source = ElectrosurRemoteDataSource(
        clientFactory: () => ElectrosurHttpClient(transport),
      );

      final data = await source.synchronize(
        contractNumber: 'CONTRATO-FICTICIO',
        password: 'CLAVE-EFIMERA-FICTICIA',
        synchronizedAt: DateTime.utc(2026, 8, 11),
      );

      expect(data.account.meterNumber, isNull);
      expect(data.consumptionRecords, isNotEmpty);
      expect(data.paymentRecords, isNotEmpty);
      expect(data.supplyDetailsAvailable, isFalse);
    },
  );
}
