import "package:angular2/src/core/di.dart" show OpaqueToken, Provider;
import "package:angular2/src/facade/lang.dart" show Math, StringWrapper;

/**
 * A DI Token representing a unique string id assigned to the application by Angular and used
 * primarily for prefixing application attributes and CSS styles when
 * [ViewEncapsulation#Emulated] is being used.
 *
 * If you need to avoid randomly generated value to be used as an application id, you can provide
 * a custom value via a DI provider <!-- TODO: provider --> configuring the root [Injector]
 * using this token.
 */
const OpaqueToken APP_ID = const OpaqueToken("AppId");
String appIdRandomProviderFactory() {
  return '''${ _randomChar ( )}${ _randomChar ( )}${ _randomChar ( )}''';
}

/**
 * Providers that will generate a random APP_ID_TOKEN.
 */
const Provider APP_ID_RANDOM_PROVIDER = const Provider(APP_ID,
    useFactory: appIdRandomProviderFactory, deps: const []);
String _randomChar() {
  return StringWrapper.fromCharCode(97 + Math.floor(Math.random() * 25));
}

/**
 * A function that will be executed when a platform is initialized.
 */
const OpaqueToken PLATFORM_INITIALIZER =
    const OpaqueToken("Platform Initializer");
/**
 * A function that will be executed when an application is initialized.
 */
const OpaqueToken APP_INITIALIZER =
    const OpaqueToken("Application Initializer");
/**
 * A token which indicates the root directory of the application
 */
const OpaqueToken PACKAGE_ROOT_URL =
    const OpaqueToken("Application Packages Root URL");
