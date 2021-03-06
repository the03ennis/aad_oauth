import 'dart:async';
import 'package:aad_oauth_web/model/token.dart';
import "dart:convert" as Convert;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; //Will be used to determine if web storage is necessary
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthStorage {
  static AuthStorage shared = new AuthStorage();
  AuthStorage storageInstance;
  String _tokenIdentifier;

  ///Modified this constructor: if the program is running on web, it will return
  ///an intance of webstorage. Otherwise, it will return an instance of FSStorage,
  ///which utilizes flutter_secure_storage
  AuthStorage({String tokenIdentifier = "Token"}) {
    _tokenIdentifier = tokenIdentifier;
    if (kIsWeb) {
      storageInstance =
          new WebStorageInstance(tokenIdentifier: tokenIdentifier);
    } else {
      storageInstance = new FSStorageInstance(tokenIdentifier: tokenIdentifier);
    }
  }

  Future<void> saveTokenToCache(Token token) async {
    storageInstance.saveTokenToCache(token);
  }

  Future<T> loadTokenToCache<T extends Token>() async {
    return storageInstance.loadTokenToCache();
  }

  Token _getTokenFromMap<T extends Token>(Map<String, dynamic> data) =>
      Token.fromJson(data);

  Future clear() async {
    storageInstance.clear();
  }
}

class WebStorageInstance implements AuthStorage {
  AuthStorage storageInstance;
  String _tokenIdentifier;
  var authBox; //A Hive box for the storage of credentials
  //Basic constructor for the web secure storage instance.
  WebStorageInstance({String tokenIdentifier = "Token"}) {
    storageInstance = this;
    //Initiates hive
    Hive.initFlutter();
    _tokenIdentifier = tokenIdentifier;
    //Opens the box
    authBox = Hive.openBox('authBox');
  }

  @override
  Future<void> saveTokenToCache(Token token) async {
    authBox = await Hive.openBox('authBox');
    var data = Token.toJsonMap(token);
    var json = Convert.jsonEncode(data);
    await authBox.put(_tokenIdentifier, json);
  }

  @override
  Future<T> loadTokenToCache<T extends Token>() async {
    authBox = await Hive.openBox('authBox');
    var json = await authBox.get(_tokenIdentifier);
    if (json == null) return null;
    try {
      var data = Convert.jsonDecode(json);
      return _getTokenFromMap<T>(data);
    } catch (exception) {
      print(exception);
      return null;
    }
  }

  @override
  Token _getTokenFromMap<T extends Token>(Map<String, dynamic> data) =>
      Token.fromJson(data);

  @override
  Future clear() async {
    authBox = await Hive.openBox('authBox');
    authBox.delete(_tokenIdentifier);
  }
}

///This takes the code written by the original authors and moves it into its own class.
///This will be instantiated when storage is needed on a non-web platform, ex iOS, Android
class FSStorageInstance implements AuthStorage {
  AuthStorage storageInstance;
  String _tokenIdentifier;
  FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  //Basic constructor for the flutter secure storage instance
  FSStorageInstance({String tokenIdentifier = "Token"}) {
    storageInstance = this;
    _tokenIdentifier = tokenIdentifier;
  }

  @override
  Future<void> saveTokenToCache(Token token) async {
    var data = Token.toJsonMap(token);
    var json = Convert.jsonEncode(data);
    await _secureStorage.write(key: _tokenIdentifier, value: json);
  }

  @override
  Future<T> loadTokenToCache<T extends Token>() async {
    var json = await _secureStorage.read(key: _tokenIdentifier);
    if (json == null) return null;
    try {
      var data = Convert.jsonDecode(json);
      return _getTokenFromMap<T>(data);
    } catch (exception) {
      print(exception);
      return null;
    }
  }

  @override
  Token _getTokenFromMap<T extends Token>(Map<String, dynamic> data) =>
      Token.fromJson(data);

  @override
  Future clear() async {
    _secureStorage.delete(key: _tokenIdentifier);
  }
}
