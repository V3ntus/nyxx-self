import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:logging/logging.dart';
import 'package:nyxx_self/src/events/http_events.dart';
import 'package:nyxx_self/src/events/ratelimit_event.dart';
import 'package:nyxx_self/src/internal/event_controller.dart';
import 'package:nyxx_self/src/internal/interfaces/disposable.dart';
import 'package:nyxx_self/src/nyxx.dart';
import 'package:nyxx_self/src/internal/http/http_bucket.dart';
import 'package:nyxx_self/src/internal/http/http_request.dart';
import 'package:nyxx_self/src/internal/http/http_response.dart';
import 'package:nyxx_self/src/utils/utils.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class HttpHandler implements Disposable {
  late final http.Client httpClient;
  Map<String, dynamic>? superProps;

  final Logger logger = Logger("Http");
  final INyxxRest client;

  RestEventController get _events => client.eventsRest as RestEventController;

  final Map<String, HttpBucket> _bucketByRequestRateLimitId = {};
  DateTime globalRateLimitReset = DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates an instance of [HttpHandler]
  HttpHandler(this.client) {
    // HttpOverrides.global = DevHttpOverrides();
    httpClient = http.Client();

    getBrowserInfo().then((clientInfo) => superProps = {
      'os': 'Windows',
      'browser': 'Chrome',
      'device': '',
      'browser_user_agent': clientInfo[0],
      'browser_version': clientInfo[1],
      'os_version': '10',
      'referrer': '',
      'referring_domain': '',
      'referrer_current': '',
      'referring_domain_current': '',
      'release_channel': 'stable',
      'system_locale': 'en-US',
      'client_build_number': clientInfo[2],
      'client_event_source': null,
      'design_id': 0,
    });
  }

  HttpBucket? _upsertBucket(HttpRequest request, http.StreamedResponse response) {
    //Get or Create Bucket
    final bucket = _bucketByRequestRateLimitId.values.toList().firstWhereSafe((bucket) => bucket.isInBucket(response)) ?? HttpBucket.fromResponseSafe(response);
    //Update Bucket
    bucket?.updateRateLimit(response);

    //Update request -> bucket mapping
    if (bucket != null) {
      _bucketByRequestRateLimitId.update(
        request.rateLimitId,
        (b) => bucket,
        ifAbsent: () => bucket,
      );
    }

    return bucket;
  }

  Future<int> _getBuildNumber() async {
    RegExp assetRegex = RegExp(r"assets/+([a-z0-9]+\.js)");
    http.Response res = await httpClient.get(Uri(
      scheme: "https",
      host: "discord.com",
      path: "/login",
    ));
    http.Response assetRes = await httpClient.get(Uri(
      scheme: "https",
      host: "discord.com",
      path: "/assets/${assetRegex.allMatches(res.body).toList()[-2]}.js",
    ));
    int buildIndex = assetRes.body.indexOf("buildNumber") + 24;
    return int.tryParse(assetRes.body.substring(buildIndex, buildIndex + 6)) ?? 9999;
  }

  Future<String> _getUserAgent() async {
    try {
      http.Response res = await httpClient.get(Uri(
        scheme: "https",
        host: "jnrbsn.github.io",
        path: "/user-agents/user-agents.json",
      ));
      String ua = jsonDecode(res.body)[0].toString();
      return ua;
    } catch (err) {
      return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36";
    }
  }

  /// Returns a list with: user agent, browser version, and build number in order.
  Future<List<dynamic>> getBrowserInfo() async {
    String ua;
    String bv;
    int bn;
    for (var i = 0; i < 3; i++) {
      try {
        http.Response res = await httpClient.get(Uri(
          scheme: "https",
          host: "cordapi.dolfi.es",
          path: "/api/v1/properties/web",
        ));
        dynamic json = jsonDecode(res.body);
        ua = json["chrome_user_agent"].toString();
        bv = json["chrome_version"].toString();
        bn = int.parse(json["client_build_number"].toString());
        return [ua, bv, bn];
      } catch (err) {
        continue;
      }
    }
    ua = await _getUserAgent();
    bn = await _getBuildNumber();
    bv = ua.split("Chrome/")[1].split(" ")[0];
    // i'm so frickn lazy
    superProps = {
      'os': 'Windows',
      'browser': 'Chrome',
      'device': '',
      'browser_user_agent': ua,
      'browser_version': bv,
      'os_version': '10',
      'referrer': '',
      'referring_domain': '',
      'referrer_current': '',
      'referring_domain_current': '',
      'release_channel': 'stable',
      'system_locale': 'en-US',
      'client_build_number': bn,
      'client_event_source': null,
      'design_id': 0,
    };
    return [ua, bv, bn];
  }

  Future<HttpResponse> execute(HttpRequest request) async {
    if (request.auth) {
      request.headers.addAll({"Authorization": client.token});
    }

    HttpBucket? currentBucket = _bucketByRequestRateLimitId[request.rateLimitId];

    logger.fine('Executing request $request');
    logger.finer([
      'Headers: ${request.headers}',
      'Authenticated: ${request.auth}',
      if (request.auditLog != null) 'Audit Log Reason: ${request.auditLog}',
      'Global rate limit: ${request.globalRateLimit}',
      'Rate limit ID: ${request.rateLimitId}',
      'Rate limit bucket: ${currentBucket?.id}',
      if (currentBucket != null) ...[
        'Reset at: ${currentBucket.reset}',
        'Reset after: ${currentBucket.resetAfter}',
        'Remaining: ${currentBucket.remaining}',
      ],
      if (request is BasicRequest) 'Request body: ${request.body}',
      if (request is MultipartRequest) ...[
        'Request body: ${request.fields}',
        'Files: ${request.files.map((file) => file.filename).join(', ')}',
      ],
    ].join('\n'));

    // Get actual time and check if request can be executed based on data that bucket already have
    // and wait if rate limit could be possibly hit
    final now = DateTime.now();
    final globalWaitTime = request.globalRateLimit ? globalRateLimitReset.difference(now) : Duration.zero;
    final bucketWaitTime = (currentBucket?.remaining ?? 1) > 0 ? Duration.zero : currentBucket!.reset.difference(now);
    final waitTime = globalWaitTime.compareTo(bucketWaitTime) > 0 ? globalWaitTime : bucketWaitTime;

    if (globalWaitTime > Duration.zero) {
      logger.warning("Global rate limit reached on endpoint: ${request.uri}");
    }

    if (bucketWaitTime > Duration.zero) {
      logger.warning("Bucket rate limit reached on endpoint: ${request.uri}");
    }

    if (waitTime > Duration.zero) {
      logger.warning("Trying to send request again in $waitTime");
      _events.onRateLimitedController.add(RatelimitEvent(request, true));
      return await Future.delayed(waitTime, () async => await execute(request));
    }

    // Execute request
    currentBucket?.addInFlightRequest(request);
    final response = await client.options.httpRetryOptions.retry(
      () async => httpClient.send(await request.prepareRequest(this)),
      onRetry: (ex) => logger.warning('Exception when sending HTTP request (retrying automatically)', ex),
    );
    currentBucket?.removeInFlightRequest(request);
    currentBucket = _upsertBucket(request, response);
    return _handle(request, response);
  }

  Future<HttpResponse> _handle(HttpRequest request, http.StreamedResponse response) async {
    logger.fine('Handling response (${response.statusCode}) from request $request');
    logger.finer('Headers: ${response.headers}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseSuccess = await HttpResponseSuccess.fromResponse(response);

      (client.eventsRest as RestEventController).onHttpResponseController.add(HttpResponseEvent(responseSuccess));
      logger.finest('Successful response: $responseSuccess');

      return responseSuccess;
    }

    final responseError = await HttpResponseError.fromResponse(response);

    // Check for 429, emit events and wait given in response body time
    if (responseError.statusCode == 429) {
      final responseBody = responseError.jsonBody;
      final retryAfter = Duration(milliseconds: ((responseBody["retry_after"] as double) * 1000).ceil());
      final isGlobal = responseBody["global"] as bool;

      if (isGlobal) {
        globalRateLimitReset = DateTime.now().add(retryAfter);
      }

      _events.onRateLimitedController.add(RatelimitEvent(request, false, response));

      logger.warning(
        "${isGlobal ? "Global " : ""}Rate limited via 429 on endpoint: ${request.uri}. Trying to send request again in $retryAfter",
        responseError,
      );

      return Future.delayed(retryAfter, () => execute(request));
    }

    (client.eventsRest as RestEventController).onHttpErrorController.add(HttpErrorEvent(responseError));
    logger.finest('Unknown/error response: ${responseError.toString(short: true)}', responseError);

    return responseError;
  }

  @override
  Future<void> dispose() async => httpClient.close();
}
