@TestOn('browser')
library angular_simple_test;

import 'package:examples.github_issues/api.dart';
import 'package:examples.github_issues/ui.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'issue_body_test.template.dart' as ng;

void main() {
  ng.initReflector();
  tearDown(disposeAnyRunningTest);

  group('$IssueBodyComponent', () {
    test('should properly render markdown', () async {
      var testBed = NgTestBed<IssueBodyComponent>();
      var fixture = await testBed.create(beforeChangeDetection: (c) {
        c.issue = GithubIssue(
          description: '**Hello World**',
        );
      });
      expect(
        fixture.rootElement.innerHtml,
        contains('<strong>Hello World</strong>'),
      );
    });
  });
}
