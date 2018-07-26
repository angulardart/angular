import 'package:angular/angular.dart';

@Pipe('pure', pure: true)
class PurePipe implements PipeTransform {
  transform(value) => value;
}

@Pipe('dirty', pure: false)
class DirtyPipe implements PipeTransform {
  transform(value) => value;
}

@Pipe('lifecycle')
class LifecyclePipe implements PipeTransform, OnDestroy {
  transform(value) => value;

  @override
  void ngOnDestroy() {}
}

class C {}

@Pipe('types')
class TypesPipe implements PipeTransform {
  String transform(
    String value, [
    int a,
    dynamic b,
    C c,
    void Function(String) d,
  ]) =>
      value;
}

@Component(
  selector: 'comp',
  pipes: [
    PurePipe,
    DirtyPipe,
    LifecyclePipe,
    TypesPipe,
  ],
  template: r'''
    {{ "foo" | pure }}
    {{ "bar" | dirty }}
    {{ "lifecycle" | lifecycle }}
    {{ "types" | types:1:2:c:d }}
  ''',
)
class Comp {
  C c;

  void d(String value) {}
}
