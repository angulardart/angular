import 'package:angular/angular.dart';

@Component(
  selector: 'styles',
  template: r'''
    <div [style.width]="'5px;'" class="foo" [attr.class]="bar"></div>
  ''',
)
class StylesComponent {
  final bar = 'bar';

  @HostBinding('class')
  static final baz = 'baz';
}
