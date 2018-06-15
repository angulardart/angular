import 'dart:async';

import 'package:angular/angular.dart';

/// Sample component used to test code generation for @deferred components.
@Component(
  selector: 'my-deferred-view',
  template: r'''
    <button (click)="doClick()" [attr.selected]="isSelected">
      Title:&ngsp;{{title}}
    </button>
  ''',
)
class DeferredChildComponent extends SomeBaseClass {
  final _onSelected = StreamController<bool>.broadcast(sync: true);
  bool isSelected = false;

  @Input()
  set title(String value) {
    titleBase = value;
  }

  @Output()
  Stream<bool> get selected => _onSelected.stream;

  String get title => titleBase;

  void doClick() {
    isSelected = true;
    _onSelected.add(isSelected);
  }
}

class SomeBaseClass {
  String titleBase;
}
