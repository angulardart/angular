import 'package:angular/angular.dart';

@Component(
  selector: 'host',
  template: '',
  host: const {
    'aria-title': 'title',
    '(keydown)': 'onKeyDown()',
  },
)
class HostComponent {
  @HostBinding()
  String get title => 'Hello';

  @HostBinding('class.is-disabled')
  bool get isDisabled => true;

  @HostBinding('class.foo')
  static const bool hostClassFoo = true;

  @HostBinding('style.color')
  static const String hostStyleColor = 'red';

  @HostListener('click', const [r'$event'])
  void onClick(event) {}

  void onKeyDown() {}
}
