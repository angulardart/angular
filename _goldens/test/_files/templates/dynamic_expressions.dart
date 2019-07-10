import 'package:angular/angular.dart';

// OK: Compiles to "_ctx.a + _ctx.b"
@Component(
  selector: 'comp-1',
  template: '{{a + b}}',
)
class Comp1 {
  var a = 1;
  var b = 2;
}

// OK: Compiles to "_ctx.a + _ctx.b"
@Component(
  selector: 'comp-1-string',
  template: '{{a + b}}',
)
class Comp1String {
  var a = "1";
  var b = "2";
}

// OK: Compiles to "_ctx.a.b(_ctx.c)"
@Component(
  selector: 'comp-2',
  template: '{{a.b(c)}}',
)
class Comp2 {
  var a = Comp2Model();
  var c = 'Hello World';
}

class Comp2Model {
  String b(String c) => c;
}

// OK: Compiles to "import1.Comp3.max(_ctx.a, _ctx.b).toInt().isEven"
@Component(
  selector: 'comp-3',
  template: '{{max(a, b).toInt().isEven}}',
)
class Comp3 {
  static T max<T extends Comparable<T>>(T a, T b) {
    return a.compareTo(b) < 0 ? b : a;
  }

  num a = 0;
  num b = 1;
}

// Dynamic :(
//
// Compiles to:
//   "List<dynamic> Function(dynamic, dynamic) _arr_0;"
//   "_arr_0 = import6.pureProxy2((p0, p1) => [p0, p1])"
// ...
//   "_arr_0(_ctx.a, _ctx.b).first.inMilliseconds"
@Component(
  selector: 'comp-4',
  template: '{{[a, b].first.inMilliseconds}}',
)
class Comp4 {
  var a = Duration(seconds: 1);
  var b = Duration(seconds: 2);
}

// OK!
//
// Compiles to:
//    "final local_duration = import7.unsafeCast<Duration>(locals['\$implicit']);"
//    "final currVal_0 = import6.interpolate0(local_duration.inMilliseconds);"
@Component(
  selector: 'comp-6',
  directives: [NgFor],
  template: r'''
    <ng-container *ngFor="let duration of durations">
      {{duration.inMilliseconds}}
    </ng-container>
  ''',
)
class Comp6 {
  var durations = [Duration(seconds: 1)];
}

// OK!
//
// Compiles to:
//    "final local_durations = import7.unsafeCast<List<Duration>>(locals['\$implicit']);"
//    "final currVal_0 = local_durations;"
//    "if (import6.checkBinding(_expr_0, currVal_0)) {"
//      "_NgFor_0_9.ngForOf = currVal_0;"
//      "_expr_0 = currVal_0;"
//    "}"
// ...
//    "final local_duration = import7.unsafeCast<Duration>(locals['\$implicit']);"
//    "final currVal_0 = import6.interpolate0(local_duration.inMilliseconds);"
@Component(
  selector: 'comp-7',
  directives: [NgFor],
  template: r'''
    <ng-container *ngFor="let durations of items">
      <ng-container *ngFor="let duration of durations">
        {{duration.inMilliseconds}}
      </ng-container>
    </ng-container>
  ''',
)
class Comp7 {
  var items = [
    [Duration(seconds: 1)]
  ];
}
