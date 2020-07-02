import 'package:flutter_test/flutter_test.dart';

import 'package:aad_oauth_web/aad_oauth_web.dart';
import 'package:aad_oauth_web/model/config.dart';

void main() {
  test('adds one to input values', () {
    final Config config = new Config("Label", "YOUR TENANT ID",
        "YOUR CLIENT ID", "openid profile offline_access");
    final AadOAuth oauth = new AadOAuth(config);

    //TODO testing
  });
}
