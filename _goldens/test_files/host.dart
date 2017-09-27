import 'package:angular/angular.dart';

@Component(
  selector: 'host',
  template: '',
  host: const {
    'aria-title': 'title',
    '(keydown)': 'onKeyDown()',
  },
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
