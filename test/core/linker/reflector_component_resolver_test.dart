import 'package:angular2/angular2.dart';
import 'package:angular2/src/core/linker/component_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('should read factory from reflection info', () async {
    final myAppComponentFactory = new ComponentFactory(null, null, null);
    final reflectionInfo = new ReflectionInfo([myAppComponentFactory]);
    reflector.registerType(MyAppComponent, reflectionInfo);
    final componentResolver = new ReflectorComponentResolver();
    final componentFactory =
        await componentResolver.resolveComponent(MyAppComponent);
    expect(componentFactory, myAppComponentFactory);
  });
}

class MyAppComponent {}
