import 'package:angular/angular.dart';

@Component(
  selector: 'lifecycle-hooks',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
