import 'package:angular/angular.dart';

@Component(
  selector: 'lifecycle-hooks',
  directives: [
    EmptyComponent,
  ],
  template: r'''
    <empty-comp></empty-comp>
    <ng-content></ng-content>
  ''',
)
class MostLifecycleHooksComponent extends MostLifecycleHooksSuperclass {}

class MostLifecycleHooksSuperclass
    implements
        OnDestroy,
        OnInit,
        AfterContentChecked,
        AfterContentInit,
        AfterViewChecked,
        AfterViewInit {
  @Input()
  String input;

  @override
  ngAfterContentChecked() {}

  @override
  ngAfterContentInit() {}

  @override
  ngAfterViewChecked() {}

  @override
  ngAfterViewInit() {}

  @override
  ngOnDestroy() {}

  @override
  ngOnInit() {}
}

@Component(
  selector: 'empty-comp',
  template: '',
)
class EmptyComponent {}

@Directive(
  selector: 'do-check',
)
class DoCheckDirective implements DoCheck {
  @override
  void ngDoCheck() {}

  @Input()
  String input;
}

@Component(
  selector: 'after-changes',
  template: '',
)
class AfterChangesComponent implements AfterChanges {
  @override
  void ngAfterChanges() {}

  @Input()
  String input;
}

@Component(
  selector: 'uses-lifecylce-hooks',
  directives: [
    MostLifecycleHooksComponent,
    EmptyComponent,
    DoCheckDirective,
    AfterChangesComponent,
  ],
  template: r'''
    <lifecycle-hooks [input]="input">
      <empty-comp></empty-comp>
    </lifecycle-hooks>
    <do-check [input]="input"></do-check>
    <after-changes [input]="input"></after-changes>
  ''',
)
class UsesLifecycleHooksComponent {
  var input = 'Hello World';
}
