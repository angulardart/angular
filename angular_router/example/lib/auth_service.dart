import 'dart:async';

import 'package:angular/angular.dart';

@Injectable()
class AuthService {
  String redirectUrl;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<Null> login() {
    return new Future.delayed(new Duration(seconds: 1), () {
      _isLoggedIn = true;
    });
  }

  void logout() {
    _isLoggedIn = false;
  }
}
