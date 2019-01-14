# Angular Migration Guide v4 to v5

## Major changes

-   Build system switched from pub transformers to build_runner/webdev. [Dart 2
    Migration Guide for Web
    Apps](https://webdev.dartlang.org/dart-2)
-   Introduced Router 2.0. [Router Migration
    Guide](https://github.com/dart-lang/angular/blob/master/doc/router/migration.md)
-   Strictly typed injector.
-   Usage of generated `.template.dart` files for `NgFactory` referencing.

## Migration steps

AngularDart 5 and the build related dependencies require Dart 2, therefore install
`>=2.0.0-dev.64.1` SDK version before continuing. When developing in
Intellij/WebStorm make sure to adapt the configuration of your SDK path in the
dart settings.

### Update angular dependencies

```yaml
dependencies:
  angular: ^5.0.0-beta
  angular_router: ^2.0.0-alpha
  angular_forms: ^2.0.0-beta

dev_dependencies:
  angular_test: ^2.0.0-beta
```

### Switch to build_runner

Add or update the build_runner related dependencies to your `pubspec.yaml`.

```yaml
dev_dependencies:
  build_runner: ^1.0.0
  build_test: ^0.10.2
  build_web_compilers: ^1.0.0
```

> Notice: It's no longer required to use a separate tool/build.dart in case
> previous versions of build_runner where used within the project. If builders
> outside of angular are used, see [build_config
> README](https://github.com/dart-lang/build/tree/master/build_config)for
> instructions to setup an individual build configuration.

Make sure to ignore the `.dart_tool` directory in your `.gitignore`
configuration. The directory will contain the generated results of the
`build_runner`.

> Notice: When developing in Intellij/WebStorm it's currently also recommended
> to mark the directory as excluded as it will constantly change and cause
> Intellij to reanalyze the code frequently, which results in a loss of
> performance.

Drop transformer related dependencies.

-   dart_to_js_script_rewriter
-   browser

Remove transformer configuration from `pubspec.yaml`.

**Old code**

```yaml
dependencies:
  # ...

dev_dependencies:
  # ...

transformers:
- angular:
    platform_directives:
    - 'package:angular2/common.dart#COMMON_DIRECTIVES'
    platform_pipes:
    - 'package:angular2/common.dart#COMMON_PIPES'
    entry_points: web/main.dart
- test/pub_serve:
    $include:
      - test/**.dart
- dart_to_js_script_rewriter
```

**New code**

```yaml
dependencies:
  # ...

dev_dependencies:
  # ...
```

#### Building for deployment

In order to create a release build run `pub run build_runner build --release
--output <directory>`. This will create the directory including the `dart2js`
build result and cleanup unused files for the deployment.

### Adjust analysis_options.yaml

There are several cases where `.template.dart` files are included (ex.
`main.dart` and async routes). Therefore ignoring the
`uri_has_not_been_generated` error within the `analysis_options.yaml` will
prevent the analyzer from reporting unnecessary issues.

```yaml
analyzer:
  errors:
    uri_has_not_been_generated: ignore
    # ...
```

For further information on how to customize the analyzer see [Customize Static
Analysis](https://www.dartlang.org/guides/language/analysis-options).

### Setting up the root injector and runApp

angular 5.0 introduced `GenerateInjector`, which generates an injector at
compile-time and as such enables better tree-shaking. This requires to import
the generated `.template.dart` file within the injector setup file (ex.
`main.dart`).

**Old code (`main.dart`)**

```dart
import 'package:my_app/app_component.dart';

void main() {
  bootstrap(AppComponent, [
    provide(MyToken, useValue: 'test'),
    HeroService,
  ]);
}
```

**New code (`main.dart`)**

```dart
import 'package:my_app/app_component.template.dart' as ng;
import 'main.template.dart' as self;

@GenerateInjector([
  ValueProvider.forToken(MyToken, 'test'),
  ClassProvider(HeroService),
])
final InjectorFactory injectorFactory = self.injectorFactory$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injectorFactory);
}
```

When using `runApp()` it's possible to enable `angular_compiler` settings, which
will reduce the DDC load times during development, by adding the following lines
to the `build.yaml`:

```yaml
global_options:
  angular|angular:
    options:
      no-emit-component-factories: True
      no-emit-injectable-factories: True
```

For further information about best practices for the dependency injector see
[Effective AngularDart: Dependency
Injection](https://github.com/dart-lang/angular/blob/master/doc/effective/dependency-injection.md#injectors).

### Refactor providers to use typed variant

With the new version it's no longer necessary to use `@Injector` annotations for
services, which will be used by the `Injector`. There are also now typed
equivalents to `provide` and `const Provider`.

**Old code**

```dart
@Component(
  selector: 'my-component',
  template: '',
  providers: const [
    provide(MyToken, useValue: 'test'),
    MyService,
    provide(MyInterface, useClass: MyImplementation),
    provide(MyOtherClass, useFactory: myOtherClassFactory),
    provide(MultiToken, multi: true, useValue: 'val 1'),
    provide(MultiToken, multi: true, useFactory: tokenFactory),
    provide(SomeInterface, useExisting: ExistingImplementation),
  ],
)
```

**New code**

```dart
@Component(
  selector: 'my-component',
  template: '',
  providers: [
    ValueProvider.forToken(MyToken, 'test'),
    ClassProvider(MyService),
    ClassProvider(MyInterface, MyImplementation),
    FactoryProvider(MyOtherClass, myOtherClassFactory),
    ValueProvider.forToken(MultiToken, 'val 1', multi: true),
    FactoryProvider.forToken(MultiToken, tokenFactory, multi: true),
    ExistingProvider(SomeInterface, ExistingImplementation),
  ],
)
```

> Notice: This example already makes use of [optional
> new/const](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/implicit-creation.md).

This of course also applies to the setup of an `Injector` within `main.dart`.
For further information about providers see [Effective AngularDart: Dependency
Injection](https://github.com/dart-lang/angular/blob/master/doc/effective/dependency-injection.md#providers).

### Adjust deferred loaded components

There's a complete [Router Migration
Guide](https://github.com/dart-lang/angular/blob/master/doc/router/migration.md)
available within the `doc` section.

### Remove usage of DynamicComponentLoader

`DynamicComponentLoader` was renamed to `SlowComponentLoader` and should no
longer be used. It's encouraged to use the new `ComponentLoader` which requires
the generated `ComponentFactory`. There's a guide about [component
loading](https://github.com/dart-lang/angular/blob/master/doc/faq/component-loading.md#overview)
available within the `doc` section.

### Change QueryList to List

`QueryList` is removed and needs to be replaced with a simple `List`.

**Old code**

```dart
class MyComponent implements OnInit {
  @ViewChildren(MyOtherComponent)
  QueryList<MyOtherComponent> components;

  @ViewChildren(ChangingComponent)
  QueryList<ChangingComponent> changing;

  @override
  void ngOnInit() {
    changing.changes.listen((_) => print('items changed'));
  }
}
```

**New code**

```dart
class MyComponent {
  @ViewChildren(MyOtherComponent)
  QueryList<MyOtherComponent> components;

  @ViewChildren(ChangingComponent)
  set changing(List<ChangingComponent> changing) {
    print('items changed');
  }
}
```

### Refactor ElementRef to use Element

`ElementRef` has been deprecated and can be replaced by `Element` or
`HtmlElement` directly.

### Refactor OpaqueToken injections

You are now able to use an `OpaqueToken` or `MultiToken` as an annotation
directly instead of wrapping it in `@Inject`. For example, the following classes
are identically understood by AngularDart:

```dart
const baseUrl = const OpaqueToken<String>('baseUrl');

class Comp1 {
  Comp1(@Inject(baseUrl) String url);
}

class Comp2 {
  Comp2(@baseUrl String url);
}
```

### Move internationalisation to exports

Previously it was necessary to redirect `intl` translations using properties
within the `Component` because it was the only way to provide them to the
template. Now it's possible to pass the translation functions to the `exports`:

**Old code**

```dart
String msgInformation() => Intl.message('Further information:', name: 'msgInformation');

@Component(
  selector: 'my-component',
  template: '<span>{{msgInfo}}</span>',
)
class MyComponent {
  String get msgInfo => msgInformation();
}
```

**New code**

```dart
String msgInformation() => Intl.message('Further information:', name: 'msgInformation');

@Component(
  selector: 'my-component',
  template: '<span>{{msgInformation()}}</span>',
  exports: const [msgInformation],
)
class MyComponent {}
```
