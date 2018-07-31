@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'bed_static_test.template.dart' as ng_generated;

void main() {
  // Intentional explicit lack of ng_generated.initReflector().

  test('should create a component with a ComponentFactory', () async {
    final testBed = NgTestBed.forComponent(
      ng_generated.ExampleCompNgFactory,
      rootInjector: mathInjector,
    );
    final fixture = await testBed.create();
    expect(fixture.text, '0');
    await fixture.update((comp) => comp
      ..a = 1
      ..b = 2);
    expect(fixture.text, '3');
  });
}

@GenerateInjector([
  Provider(MathService),
])
final InjectorFactory mathInjector = ng_generated.mathInjector$Injector;

class MathService {
  num add(num a, num b) => a + b;
}

@Component(
  selector: 'example',
  template: '{{math.add(a, b)}}',
)
class ExampleComp {
  final MathService math;

  var a = 0;
  var b = 0;

  ExampleComp(this.math);
}
