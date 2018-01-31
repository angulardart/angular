import 'package:angular/angular.dart';

@Component(
  selector: 'admin-heroes',
  template: '''
      <p>Manage your heroes here</p>
    ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class AdminHeroesComponent {}
