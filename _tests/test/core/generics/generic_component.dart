import 'dart:async';

import 'package:angular/angular.dart';

@Component(
  selector: 'generic',
  template: '',
)
class GenericComponent<T> {
  final _controller = StreamController<T>();

  @Input()
  set input(T value) {
    _controller.add(value);
  }

  @Output()
  Stream<T> get output => _controller.stream;
}
