import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

@Component(
  selector: 'admin-dashboard',
  template: '''
      <p>Dashboard</p>

      <p>Session ID: {{sessionId}}</p>
      <a id="anchor"></a>
      <p>Token: {{token}}</p>
    ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class AdminDashboardComponent implements OnActivate {
  String sessionId;
  String token;

  @override
  void onActivate(_, RouterState nextState) {
    sessionId = nextState.queryParameters['sessionId'] ?? 'None';
    token = nextState.fragment ?? 'None';
  }
}
