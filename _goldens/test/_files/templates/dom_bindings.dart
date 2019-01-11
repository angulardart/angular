import 'package:angular/angular.dart';

@Component(
  selector: 'has-host-attributes',
  template: '',
)
class HasHostAttributes {
  @HostBinding('attr.title')
  var title = 'Hello';
}

@Component(
  selector: 'has-template-attributes',
  template: r'''
    <div [attr.title]="title"></div>
  ''',
)
class HasTemplateAttributes {
  var title = 'Hello';
}

@Component(
  selector: 'has-host-class',
  template: '',
)
class HasHostClass {
  @HostBinding('class.fancy')
  var fancy = true;
}

@Component(
  selector: 'has-template-class',
  template: r'''
    <div [class.fancy]="fancy"></div>
  ''',
)
class HasTemplateClass {
  var fancy = true;
}
