import 'dart:async';

import 'package:pageloader/objects.dart';

/// Page object for `my-app` component.
@EnsureTag('my-app')
class AppComponentPO {
  @ByTagName('my-dashboard')
  @optional
  Lazy<PageLoaderElement> dashboard;

  @ByTagName('my-hero-detail')
  @optional
  Lazy<PageLoaderElement> heroDetail;

  @ByTagName('my-heroes')
  @optional
  Lazy<PageLoaderElement> heroes;

  @ByTagName('login')
  @optional
  Lazy<LoginComponentPO> login;

  @ByTagName('admin')
  @optional
  Lazy<AdminComponentPO> admin;
}

@EnsureTag('login')
class LoginComponentPO {
  @ById('username')
  PageLoaderElement _username;

  @ById('password')
  PageLoaderElement _password;

  @ByClass('login-button')
  PageLoaderElement _loginButton;

  Future login(String username, String password) async {
    await _username.type(username);
    await _password.type(password);
    await _loginButton.click();
  }
}

@EnsureTag('admin')
class AdminComponentPO {
  @ByTagName('admin-dashboard')
  @optional
  Lazy<PageLoaderElement> adminDashboard;

  @ByTagName('admin-heroes')
  @optional
  Lazy<PageLoaderElement> adminHeroes;
}
