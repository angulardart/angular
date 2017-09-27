import 'package:angular/angular.dart';

@Component(
  selector: 'admin-heroes',
  template: '''
      <p>Manage your heroes here</p>
    ''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class AdminHeroesComponent {}
