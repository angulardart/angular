import 'package:angular/angular.dart';

@Component(
  selector: 'lifecycle-hooks',
  template: '',
)
class LifecycleHooksComponent extends LifecycleHooksSuperclass {}

class LifecycleHooksSuperclass
    implements
        OnDestroy,
        OnChanges,
        OnInit,
        AfterContentChecked,
        AfterContentInit,
        AfterViewChecked,
        AfterViewInit,
        DoCheck {
  @override
  ngAfterContentChecked() {}

  @override
  ngAfterContentInit() {}

  @override
  ngAfterViewChecked() {}

  @override
  ngAfterViewInit() {}

  @override
  ngDoCheck() {}

  @override
  ngOnChanges(_) {}

  @override
  ngOnDestroy() {}

  @override
  ngOnInit() {}
}
