import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; //Will be used to determine if iframe is necessary

class RequestCode {
  AuthorizationRequest _authorizationRequest;
  RequestCode requestCodeInstance;

  RequestCode(Config config) {
    _authorizationRequest = new AuthorizationRequest(config);
    if (kIsWeb) {
      this.requestCodeInstance = new WebRequestCode(config);
    } else {
      this.requestCodeInstance = new MobileRequestCode(config);
    }
  }

  Future<String> requestCode() async {
    return requestCodeInstance.requestCode();
  }

  Future<void> clearCookies() async {
    return requestCodeInstance.clearCookies();
  }

  String _constructUrlParams() => requestCodeInstance._constructUrlParams();

  String _mapToQueryParams(Map<String, String> params) {
    return requestCodeInstance._mapToQueryParams(params);
  }
}

class MobileRequestCode implements RequestCode {
  final StreamController<String> _onCodeListener = new StreamController();
  final FlutterWebviewPlugin _webView = new FlutterWebviewPlugin();
  final Config _config;
  RequestCode requestCodeInstance;

  AuthorizationRequest _authorizationRequest;

  var _onCodeStream;

  MobileRequestCode(Config config) : _config = config {
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

class WebRequestCode implements RequestCode {
  RequestCode requestCodeInstance;
  final Config _config;
  SimpleDialog _iFrameDialog;
  Widget _iFrameWidget;
  String _iFrameHeight;
  String _iFrameWidth;
  IFrameElement _iframeElement;
  AuthorizationRequest _authorizationRequest;

  WebRequestCode(Config config) : _config = config {
    _authorizationRequest = new AuthorizationRequest(config);
    requestCodeInstance = this;
    _iFrameHeight = '800';
    _iFrameWidth = '800';
    _iframeElement = IFrameElement();
    // ignore: undefined_prefix_name
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => _iframeElement,
    );
    _iframeElement.style.border = 'none';
    _iframeElement.height = _iFrameHeight;
    _iframeElement.width = _iFrameWidth;
    _iFrameWidget = HtmlElementView(
      key: UniqueKey(),
      viewType: 'iframeElement',
    );
    _iFrameDialog = new SimpleDialog(
      children: [
        SizedBox(
          height: double.parse(_iFrameHeight),
          width: double.parse(_iFrameWidth),
          child: _iFrameWidget,
        )
      ],
    );
  }

  Future<String> requestCode() async {
    final String urlParams = _constructUrlParams();
    _iframeElement.src =
        Uri.encodeFull("${_authorizationRequest.url}?$urlParams");
    Get.dialog(_iFrameDialog);
  }

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params
        .forEach((String key, String value) => queryParams.add("$key=$value"));
    return queryParams.join("&");
  }

  Future<void> clearCookies() async {
    //Do nothing
  }
}
