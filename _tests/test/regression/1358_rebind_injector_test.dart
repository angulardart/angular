@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:test/test.dart';

import '1358_rebind_injector_test.template.dart' as ng;

void main() {
  ng.initReflector();

  ReflectiveInjector parentInjector;

  setUp(() {
    parentInjector = ReflectiveInjector.resolveAndCreate([
      new ClassProvider(Model),
      new ValueProvider(Place, new Place('Parent')),
    ]);
  });

  test('should have the expected bindings at the parent level', () {
    expect((parentInjector.get(Model) as Model).place.name, 'Parent');
  });

  test('should have the expected bindings at the child level', () {
    final childInjector = parentInjector.resolveAndCreateChild([
      new ValueProvider(Place, new Place('Child')),
    ]);
    expect(
      (childInjector.resolveAndInstantiate(Model) as Model).place.name,
      'Child',
    );
  });
}

class Place {
  final String name;

  Place(this.name);

  @override
  String toString() => '$Place {name=$name}';
}

@Injectable()
class Model {
  final Place place;

  Model(this.place);

  @override
  String toString() => '$Model {place=$place}';
}
