@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'pipes.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  template: r'''
    <div>
      Using "pure" Pipes:
      <div>
        IDENTITY:   {{ $pipe.identity(a) }}
      </div>
      <div>
        CONCAT:     {{ $pipe.concat(a, b) }}
      </div>
      <div>
        MERGE:      {{ $pipe.merge(a, b) }}
      </div>
      <div>
        TYPED:      {{ $pipe.typed(a, 1) }}
      </div>
      <div>
        LIFECYCLE:  {{ $pipe.pureLifecycle(a) }}
      </div>
    </div>
    <div>
      Using "impure" Pipes:
      <div>
        TIME:       {{ $pipe.time('now') }}
      </div>
      <div>
        LIFECYCLE:  {{ $pipe.impureLifecycle(a) }}
      </div>
    </div>
  ''',
  pipes: [
    IdentityPurePipe,
    ConcatPurePipe,
    MergePurePipe,
    TypedPurePipe,
    PureLifecyclePipe,
    ImpureTimePipe,
    ImpureLifecyclePipe,
  ],
)
class GoldenComponent {
  GoldenComponent() {
    deopt(() {
      a = deopt();
      b = deopt();
    });
  }

  late String a;
  late String b;
}

@Pipe('identity')
class IdentityPurePipe {
  Object transform(Object a) => a;
}

@Pipe('concat')
class ConcatPurePipe {
  String transform(String a, String b) {
    return '$a$b';
  }
}

@Pipe('merge')
class MergePurePipe {
  List<T> transform<T>(T a, T b) => [a, b];
}

@Pipe('typed')
class TypedPurePipe {
  Map<String, int> transform(String a, int b) => {a: b};
}

@Pipe('pureLifecycle')
class PureLifecyclePipe implements OnInit, OnDestroy {
  @override
  void ngOnInit() {
    deopt('ngOnInit');
  }

  @override
  void ngOnDestroy() {
    deopt('ngOnDestroy');
  }

  Object transform(Object a) => deopt(a);
}

@Pipe('time', pure: false)
class ImpureTimePipe {
  String transform([Object? a]) => DateTime.now().toString();
}

@Pipe(
  'impureLifecycle',
  pure: false,
)
class ImpureLifecyclePipe implements OnDestroy {
  @override
  void ngOnDestroy() {
    deopt('ngOnDestroy');
  }

  Object transform(Object a) => deopt(a);
}
