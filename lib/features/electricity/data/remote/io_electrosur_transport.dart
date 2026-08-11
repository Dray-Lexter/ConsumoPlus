import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';

import 'electrosur_endpoints.dart';
import 'electrosur_request.dart';
import 'electrosur_response.dart';
import 'electrosur_transport.dart';

class IoElectrosurTransport implements ElectrosurTransport {
  IoElectrosurTransport({Duration timeout = const Duration(seconds: 20)})
    : _timeout = timeout,
      _client = io.HttpClient() {
    _client.connectionTimeout = timeout;
    _client.userAgent = 'ConsumoPlus/0.1.0';
  }

  final Duration _timeout;
  final io.HttpClient _client;
  final _cookies = <String, io.Cookie>{};
  var _closed = false;

  @override
  Future<ElectrosurResponse> send(ElectrosurRequest request) async {
    if (_closed || !ElectrosurEndpoints.isAllowed(request.uri)) {
      throw const ElectrosurUnavailableException();
    }
    try {
      final rawRequest = await _open(request).timeout(_timeout);
      rawRequest.followRedirects = false;
      rawRequest.maxRedirects = 0;
      rawRequest.cookies.addAll(_cookies.values);
      if (request.method == 'POST') {
        rawRequest.headers.contentType = io.ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        );
        rawRequest.write(Uri(queryParameters: request.formFields).query);
      }

      late final io.HttpClientResponse rawResponse;
      try {
        rawResponse = await rawRequest.close().timeout(_timeout);
      } on TimeoutException {
        rawRequest.abort();
        throw const ElectricityNetworkTimeoutException();
      }
      final cookieNames = <String>{};
      for (final cookie in rawResponse.cookies) {
        cookieNames.add(cookie.name);
        if (_belongsToPortal(cookie)) _cookies[cookie.name] = cookie;
      }
      final bodyBytes = await rawResponse
          .fold<List<int>>(<int>[], (buffer, bytes) => buffer..addAll(bytes))
          .timeout(_timeout);
      final body = utf8.decode(bodyBytes, allowMalformed: false);
      return ElectrosurResponse(
        statusCode: rawResponse.statusCode,
        uri: request.uri,
        body: body,
        location: rawResponse.headers.value(io.HttpHeaders.locationHeader),
        cookieNames: Set.unmodifiable(cookieNames),
      );
    } on ElectricityException {
      rethrow;
    } on TimeoutException {
      throw const ElectricityNetworkTimeoutException();
    } on io.SocketException {
      throw const ElectrosurUnavailableException();
    } on io.HttpException {
      throw const ElectrosurUnavailableException();
    } on FormatException {
      throw const ElectricitySectionStructureException('response');
    } on Object {
      throw const ElectrosurUnavailableException();
    }
  }

  Future<io.HttpClientRequest> _open(ElectrosurRequest request) {
    return switch (request.method) {
      'GET' => _client.getUrl(request.uri),
      'POST' => _client.postUrl(request.uri),
      _ => throw const ElectrosurUnavailableException(),
    };
  }

  static bool _belongsToPortal(io.Cookie cookie) {
    final domain = cookie.domain?.replaceFirst(RegExp(r'^\.'), '');
    return domain == null || domain == 'www.electrosur.com.pe';
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _cookies.clear();
    _client.close(force: true);
  }

  @override
  String toString() => 'IoElectrosurTransport(configured: true)';
}
