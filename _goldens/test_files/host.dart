import 'package:angular/angular.dart';

@Component(
  selector: 'host',
  template: '',
  host: const {
    'aria-title': 'title',
    '(keydown)': 'onKeyDown()',
  },
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
