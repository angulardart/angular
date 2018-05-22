import 'package:angular/angular.dart';

@Component(
  selector: 'host',
  template: '',
  host: const {
    'class': 'themeable',
  },
)
class HostComponentDeprecatedSyntax {}

@Component(
  selector: 'host',
  template: '',
)
class HostComponentNewSyntax {
  @HostBinding('class')
  static const hostClass = 'themeable';
}

@Component(
  selector: 'host',
  template: '',
)
class HostComponent {
  @HostBinding()
  @HostBinding('attr.aria-title')
  String get title => 'Hello';

  @HostBinding('class.is-disabled')
  bool get isDisabled => true;

  @HostBinding('class.foo')
  static const bool hostClassFoo = true;

  @HostBinding('style.color')
  static const String hostStyleColor = 'red';

  @HostListener('click', const [r'$event'])
  void onClick(event) {}

  @HostListener('keydown')
  void onKeyDown() {}
}
