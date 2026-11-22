import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tehillah/core/errors/app_error.dart';

typedef HttpClientFactory = HttpClient Function();

HttpClient defaultHttpClient() => HttpClient();

/// Downloads a small text file. Throws [SocketException], [TimeoutException],
/// [HandshakeException] or [HttpException] on failure; use [classifyNetworkError]
/// to turn those into an [AppError].
Future<String> fetchText(
  Uri uri, {
  Duration timeout = const Duration(seconds: 15),
  int maxBytes = 1 << 20,
  HttpClientFactory? clientFactory,
}) async {
  final HttpClient client = (clientFactory ?? defaultHttpClient)();
  try {
    final HttpClientRequest request = await client.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    final HttpClientResponse response = await request.close().timeout(timeout);
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final String text = await utf8.decodeStream(response).timeout(timeout);
    if (text.length > maxBytes) {
      throw HttpException('response too large', uri: uri);
    }
    return text;
  } finally {
    client.close(force: true);
  }
}

/// Maps a failure from the network layer to the error taxonomy. No connection
/// or a timeout is the user's situation (retry when back online); anything else
/// the server or the transfer did is a system error.
AppError classifyNetworkError(Object error, String code) {
  if (error is AppError) {
    return error;
  }
  if (error is SocketException || error is TimeoutException || error is HandshakeException) {
    return UserRecoverableError('$code.offline', 'no usable connection', cause: error);
  }
  return SystemRecoverableError('$code.network', 'download failed: $error', cause: error);
}
