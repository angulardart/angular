import 'package:angular2/angular2.dart';

@Component(
  selector: 'lifecycle-hooks',
  template: '',
)
class LifecycleHooksComponent
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
