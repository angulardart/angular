import 'package:angular/angular.dart';

/// Tests that this simple NgIf is inlined.
@Component(
  selector: 'inlined-ngif',
  template: '''
<div *ngIf="foo">Hello World!</div>
    ''',
  directives: const [NgIf],
  visibility: Visibility.local,
)
class InlinedNgIfComponent {
  bool foo = true;
}

@Component(
  selector: 'inlined-ngif-with-immutable-condition',
  template: '''
<div *ngIf="foo">Hello World!</div>
    ''',
  directives: const [NgIf],
  visibility: Visibility.local,
)
class InlinedNgIfWithImmutableConditionComponent {
  final bool foo = true;
}
