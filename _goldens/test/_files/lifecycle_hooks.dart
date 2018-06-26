import 'package:angular/angular.dart';

@Component(
  selector: 'lifecycle-hooks',
  template: '',
)
class LifecycleHooksComponent
    implements
        OnDestroy,
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
  ngOnDestroy() {}

  @override
  ngOnInit() {}
}
