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
  selector: 'has-static-attribute',
  template: r'''
    <div [attr.title]="'title'"></div>
  ''',
)
class HasStaticAttribute {}

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

@Component(
  selector: 'has-style-property',
  template: r'''
    <div
        [style.width]="width"
        [style.height.px]="height">
    </div>
  ''',
)
class HasStyleProperty {
  var width = 0;
  var height = 12;
}
