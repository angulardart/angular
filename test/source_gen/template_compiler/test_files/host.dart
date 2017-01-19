import 'package:angular2/angular2.dart';

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

  @HostListener('click', const [r'$event'])
  void onClick(event) {}

  void onKeyDown() {}
}
