import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:nyxx/src/internal/constants.dart';
import 'package:nyxx/src/internal/http/http_route.dart';
import 'package:nyxx/src/typedefs.dart';

String _genSuperProps(Object obj) {
  return base64Encode(
    utf8.encode(jsonEncode(obj))
  );
}

abstract class HttpRequest {
  late final Uri uri;
  late final Map<String, String> headers;

  final String method;
  final RawApiMap? queryParams;
  final String? auditLog;

  final bool auth;
  final bool globalRateLimit;
  final HttpRoute route;
  String get rateLimitId => method + route.routeId;

  /// Creates and instance of [HttpRequest]
  HttpRequest(this.route, {this.method = "GET", this.queryParams, Map<String, String>? headers, this.auditLog, this.globalRateLimit = true, this.auth = true}) {
    uri = Uri.https(Constants.host, Constants.baseUri + route.path);
    this.headers = headers ?? {};
  }

  // TODO: implement UA fetch from dolfies (?) API
  Map<String, String> genHeaders() =>
      {
        ...headers,
        "Accept-Language": "en-US",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
        "Origin": "https://discord.com",
        "Pragma": "no-cache",
        "Referer": "https://discord.com/channels/@me",
        "Sec-CH-UA": '"Google Chrome";v="111", "Chromium";v="111", ";Not A Brand";v="99"',
        "Sec-CH-UA-Mobile": "?0",
        "Sec-CH-UA-Platform": '"Windows"',
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "User-Agent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36',
        "X-Discord-Locale": "en-US",
        "X-Debug-Options": "bugReporterEnabled",
        "X-Super-Properties": _genSuperProps(
          {
            'os': 'Windows',
            'browser': 'Chrome',
            'device': '',
            'browser_user_agent': "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
            'browser_version': "111.0.0.0",
            'os_version': '10',
            'referrer': '',
            'referring_domain': '',
            'referrer_current': '',
            'referring_domain_current': '',
            'release_channel': 'stable',
            'system_locale': 'en-US',
            'client_build_number': 181113,
            'client_event_source': null,
            'design_id': 0,
          }
        ),
      };

  Future<http.BaseRequest> prepareRequest();

  @override
  String toString() => '$method $uri';
}

/// [BasicRequest] with json body
class BasicRequest extends HttpRequest {
  /// Body of request
  final dynamic body;

  BasicRequest(HttpRoute route,
      {String method = "GET", this.body, RawApiMap? queryParams, String? auditLog, Map<String, String>? headers, bool globalRateLimit = true, bool auth = true})
      : super(route, method: method, queryParams: queryParams, auditLog: auditLog, headers: headers, globalRateLimit: globalRateLimit, auth: auth);

  @override
  Future<http.BaseRequest> prepareRequest() async {
    final request = http.Request(method, uri.replace(queryParameters: queryParams?.map((key, value) => MapEntry(key, value.toString()))))
      ..headers.addAll(genHeaders());

    if (body != null && method != "GET") {
      request.headers.addAll(_getJsonContentTypeHeader());
      if (body is String) {
        request.body = body as String;
      } else if (body is RawApiMap || body is RawApiList) {
        request.body = jsonEncode(body);
      }
    }

    return request;
  }

  Map<String, String> _getJsonContentTypeHeader() => {"Content-Type": "application/json"};
}

/// Request with which files will be sent. Cannot contain request body.
class MultipartRequest extends HttpRequest {
  /// Files which will be sent
  final List<http.MultipartFile> files;

  /// Additional data to sent
  final dynamic fields;

  /// Creates an instance of [MultipartRequest]
  MultipartRequest(HttpRoute route, this.files,
      {this.fields,
      String method = "GET",
      RawApiMap? queryParams,
      Map<String, String>? headers,
      String? auditLog,
      bool auth = true,
      bool globalRateLimit = true})
      : super(route, method: method, queryParams: queryParams, headers: headers, auditLog: auditLog, globalRateLimit: globalRateLimit, auth: auth);

  @override
  Future<http.BaseRequest> prepareRequest() async {
    final request = http.MultipartRequest(method, uri.replace(queryParameters: queryParams?.map((key, value) => MapEntry(key, value.toString()))))
      ..headers.addAll(genHeaders());

    request.files.addAll(files);

    if (fields != null) {
      request.fields.addAll({"payload_json": jsonEncode(fields)});
    }

    return request;
  }
}
