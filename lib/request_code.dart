import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; //Will be used to determine if iframe is necessary

class RequestCode {
  final StreamController<String> _onCodeListener = new StreamController();
  final WebView _webView = new WebView();
  final Config _config;
  RequestCode requestCodeInstance;

  AuthorizationRequest _authorizationRequest;

  var _onCodeStream;

  RequestCode(Config config) : _config = config {
    _authorizationRequest = new AuthorizationRequest(config);
    requestCodeInstance = this;
  }

  Future<String> requestCode() async {
    var code;
    final String urlParams = _constructUrlParams();

    await _webView.launch(
        Uri.encodeFull("${_authorizationRequest.url}?$urlParams"),
        clearCookies: _authorizationRequest.clearCookies,
        hidden: false,
        rect: _config.screenSize);

    _webView.onUrlChanged.listen((String url) {
      Uri uri = Uri.parse(url);

      if (uri.queryParameters["error"] != null) {
        _webView.close();
        throw new Exception("Access denied or authentation canceled.");
      }

      if (uri.queryParameters["code"] != null) {
        _webView.close();
        _onCodeListener.add(uri.queryParameters["code"]);
      }
    });

    code = await _onCode.first;
    return code;
  }

  Future<void> clearCookies() async {
    await _webView.launch("", hidden: true, clearCookies: true);
    await _webView.close();
  }

  Stream<String> get _onCode =>
      _onCodeStream ??= _onCodeListener.stream.asBroadcastStream();

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params
        .forEach((String key, String value) => queryParams.add("$key=$value"));
    return queryParams.join("&");
  }
}
