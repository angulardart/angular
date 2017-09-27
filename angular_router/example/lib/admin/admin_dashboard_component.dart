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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
