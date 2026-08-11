import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:consumo_plus/features/water/data/remote/eps_tacna_endpoints.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_transport.dart';
import 'package:consumo_plus/features/water/data/remote/in_memory_cookie_jar.dart';
import 'package:consumo_plus/features/water/data/remote/portal_request.dart';
import 'package:consumo_plus/features/water/data/remote/portal_response.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';

class IoEpsTacnaTransport implements EpsTacnaTransport {
  IoEpsTacnaTransport({
    Duration timeout = const Duration(seconds: 20),
    InMemoryCookieJar? cookieJar,
  }) : _timeout = timeout,
       _cookieJar = cookieJar ?? InMemoryCookieJar(),
       _client = io.HttpClient() {
    _client.connectionTimeout = timeout;
    _client.userAgent = 'ConsumoPlus/0.1.0';
  }

  static const _maxRedirects = 5;

  final Duration _timeout;
  final InMemoryCookieJar _cookieJar;
  final io.HttpClient _client;
  var _closed = false;

  @override
  Future<PortalResponse> send(PortalRequest request) async {
    if (_closed) throw const PortalUnavailableException();

    var current = request;
    try {
      for (
        var redirectCount = 0;
        redirectCount <= _maxRedirects;
        redirectCount++
      ) {
        _ensureAllowed(current.uri);
        final ioRequest = await _open(current).timeout(_timeout);
        ioRequest.followRedirects = false;
        ioRequest.maxRedirects = 0;
        ioRequest.cookies.addAll(_cookieJar.cookiesFor(current.uri));

        if (current.method == 'POST') {
          ioRequest.headers.contentType = io.ContentType(
            'application',
            'x-www-form-urlencoded',
            charset: 'utf-8',
          );
          ioRequest.write(Uri(queryParameters: current.formFields).query);
        }

        late io.HttpClientResponse rawResponse;
        try {
          rawResponse = await ioRequest.close().timeout(_timeout);
        } on TimeoutException {
          ioRequest.abort();
          throw const NetworkTimeoutException();
        }

        _cookieJar.store(current.uri, rawResponse.cookies);
        final body = await _readBody(rawResponse).timeout(_timeout);
        final location = rawResponse.headers.value(
          io.HttpHeaders.locationHeader,
        );
        if (_isRedirect(rawResponse.statusCode) && location != null) {
          if (redirectCount == _maxRedirects) {
            throw const PortalUnavailableException();
          }
          final redirectUri = current.uri.resolve(location);
          _ensureAllowed(redirectUri);
          final nextMethod =
              rawResponse.statusCode == io.HttpStatus.temporaryRedirect ||
                  rawResponse.statusCode == io.HttpStatus.permanentRedirect
              ? current.method
              : 'GET';
          current = PortalRequest(method: nextMethod, uri: redirectUri);
          continue;
        }

        return PortalResponse(
          statusCode: rawResponse.statusCode,
          uri: current.uri,
          body: body,
        );
      }
      throw const PortalUnavailableException();
    } on WaterException {
      rethrow;
    } on TimeoutException {
      throw const NetworkTimeoutException();
    } on io.SocketException {
      throw const PortalUnavailableException();
    } on io.HttpException {
      throw const PortalUnavailableException();
    } on Object {
      throw const PortalUnavailableException();
    }
  }

  Future<io.HttpClientRequest> _open(PortalRequest request) {
    return switch (request.method) {
      'GET' => _client.getUrl(request.uri),
      'POST' => _client.postUrl(request.uri),
      _ => throw const PortalUnavailableException(),
    };
  }

  static Future<String> _readBody(io.HttpClientResponse response) async {
    final bytes = await response.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    );
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const UnexpectedPortalStructureException();
    }
  }

  static bool _isRedirect(int statusCode) {
    return statusCode == io.HttpStatus.movedPermanently ||
        statusCode == io.HttpStatus.found ||
        statusCode == io.HttpStatus.seeOther ||
        statusCode == io.HttpStatus.temporaryRedirect ||
        statusCode == io.HttpStatus.permanentRedirect;
  }

  static void _ensureAllowed(Uri uri) {
    if (!EpsTacnaEndpoints.isAllowed(uri)) {
      throw const PortalUnavailableException();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _cookieJar.clear();
    _client.close(force: true);
  }
}
