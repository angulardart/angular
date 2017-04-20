import 'package:angular2/angular2.dart';

@Pipe('pure', pure: true)
class PurePipe implements PipeTransform {
  transform(value, _, __) => value;
}

@Pipe('dirty', pure: false)
class DirtyPipe implements PipeTransform {
  transform(value, _, __) => value;
}

@Pipe('lifecycle')
class LifecyclePipe implements PipeTransform, OnDestroy {
  transform(value, _, __) => value;

  @override
  void ngOnDestroy() {}
}

@Component(
  selector: 'comp',
  pipes: const [
    PurePipe,
    DirtyPipe,
    LifecyclePipe,
  ],
  template: r'''
    {{ "foo" | pure }}
    {{ "bar" | dirty }}
    {{ "lifecycle" | lifecycle }}
  ''',
)
class Comp {}
