import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'auth_service.dart';

@Component(selector: 'login', directives: const [NgIf], template: '''
    <h2>LOGIN</h2>
    <p>{{message}}</p>
    <div *ngIf="!loggedIn">
        <label for="username">Username</label>
        <input type="text" id="username">
        <label for="password">Password</label>
        <input type="password" id="password">
        <button class="login-button" (click)="login()" >Login</button>
    </div>
    <button (click)="logout()" *ngIf="loggedIn">Logout</button>
  ''')
class LoginComponent implements CanReuse {
  final AuthService _authService;
  final Router _router;
  String message;

  LoginComponent(this._authService, this._router);

  @override
  // Create new LoginComponent on every navigation to remove user/password.
  Future<bool> canReuse(_, RouterState newState) async => false;

  bool get loggedIn => _authService.isLoggedIn;

  void setMessage() {
    message = 'Logged ' + (_authService.isLoggedIn ? 'in' : 'out');
  }

  Future login() async {
    message = 'Trying to log in ...';

    await this._authService.login();
    setMessage();
    if (_authService.isLoggedIn) {
      String redirect = _authService.redirectUrl ?? '/admin';
      await _router.navigate(
          redirect,
          new NavigationParams(
              queryParameters: _router.current.queryParameters,
              fragment: _router.current.fragment));
    }
  }

  void logout() {
    _authService.logout();
    setMessage();
  }
}
