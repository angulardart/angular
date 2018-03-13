import 'package:angular/angular.dart';
import 'package:examples.github_issues/api.dart';
import 'package:examples.github_issues/ui.dart';

import 'main.template.dart' as ng;

@Component(
  selector: 'ng-app',
  directives: const [
    IssueListComponent,
  ],
  template: '<issue-list></issue-list>',
)
class NgAppComponent {}

void main() {
  bootstrapStatic(
    NgAppComponent,
    const [
      const ClassProvider(GithubService),
    ],
    ng.initReflector,
  );
}
