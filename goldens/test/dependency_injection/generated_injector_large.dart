@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'generated_injector_large.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

/// Shows a larger generated injector.
void main() {
  runApp(ng.createGoldenComponentFactory(), createInjector: doGenerate);
}

@Component(
  selector: 'golden',
  template: '',
)
class GoldenComponent {
  GoldenComponent(Injector i) {
    deopt(i.get);
  }
}

// Uses patterns that were found to be used extensively in large apps.
@GenerateInjector([
  // Heavy use of ExistingProvider + lots of dependencies.
  ClassProvider(UtilA0),
  ClassProvider(UtilA1),
  ClassProvider(UtilA2),
  ClassProvider(UtilA3),
  ClassProvider(UtilA4),
  ClassProvider(UtilA5),
  ClassProvider(UtilA6),
  ClassProvider(UtilA7),
  ClassProvider(UtilA8),
  ClassProvider(UtilA9),
  ExistingProvider(UtilB0, UtilA0),
  ExistingProvider(UtilB1, UtilA1),
  ExistingProvider(UtilB2, UtilA2),
  ExistingProvider(UtilB3, UtilA3),
  ExistingProvider(UtilB4, UtilA4),
  ExistingProvider(UtilB5, UtilA5),
  ExistingProvider(UtilB6, UtilA6),
  ExistingProvider(UtilB7, UtilA7),
  ExistingProvider(UtilB8, UtilA8),
  ExistingProvider(UtilB9, UtilA9),
  ClassProvider(AppUtil),
  ClassProvider(BaseUtil)
])
final InjectorFactory doGenerate = ng.doGenerate$Injector;

class BaseAppModel {}

class SuperAppModel extends BaseAppModel {}

class UtilA0 {}

class UtilA1 {}

class UtilA2 {}

class UtilA3 {}

class UtilA4 {}

class UtilA5 {}

class UtilA6 {}

class UtilA7 {}

class UtilA8 {}

class UtilA9 {}

class UtilB0 extends UtilA0 {}

class UtilB1 extends UtilA1 {}

class UtilB2 extends UtilA2 {}

class UtilB3 extends UtilA3 {}

class UtilB4 extends UtilA4 {}

class UtilB5 extends UtilA5 {}

class UtilB6 extends UtilA6 {}

class UtilB7 extends UtilA7 {}

class UtilB8 extends UtilA8 {}

class UtilB9 extends UtilA9 {}

class BaseUtil {}

class AppUtil extends BaseUtil {
  AppUtil(
    UtilB0 b0,
    UtilB1 b1,
    UtilB2 b2,
    UtilB3 b3,
    UtilB4 b4,
    UtilB5 b5,
    UtilB6 b6,
    UtilB7 b7,
    UtilB8 b8,
    UtilB9 b9,
  );
}
