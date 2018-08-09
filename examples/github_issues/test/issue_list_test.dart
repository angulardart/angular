@TestOn('browser')
library angular_complex_test;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:mockito/mockito.dart';
import 'package:examples.github_issues/api.dart';
import 'package:examples.github_issues/ui.dart';
import 'package:test/test.dart';

import 'issue_list_test.template.dart' as ng;

@Component(
  selector: 'test',
  directives: [IssueListComponent],
  template: r'<issue-list></issue-list>',
)
class ComplexTestComponent {}

void main() {
  ng.initReflector();
  tearDown(disposeAnyRunningTest);

  group('$IssueListComponent', () {
    test('should properly render markdown', () async {
      var stream = StreamController<GithubIssue>();
      var service = MockGithubService();
      when(service.getIssues()).thenAnswer((_) => stream.stream);
      var testBed = NgTestBed<ComplexTestComponent>().addProviders([
        provide(GithubService, useValue: service),
      ]);
      var fixture = await testBed.create();

      // NOT REQUIRED: We just want to slow down the test to see it.
      await Future.delayed(const Duration(seconds: 1));

      // Get a handle to the list.
      final list = IssueListPO(fixture.rootElement);
      expect(await list.isLoading, isTrue);
      expect(await list.items, isEmpty);

      // Complete the RPC.
      await fixture.update((_) {
        stream.add(
          GithubIssue(
            id: 1,
            url: Uri.parse('http://github.com'),
            title: 'First issue',
            author: 'matanlurey',
            description: 'I need **help**!',
          ),
        );
        stream.add(
          GithubIssue(
            id: 2,
            url: Uri.parse('http://github.com'),
            title: 'Second issue',
            author: 'matanlurey',
            description: 'Did you _read_ my first issue yet?',
          ),
        );
        stream.close();
      });

      // NOT REQUIRED: We just want to slow down the test to see it.
      await Future.delayed(const Duration(seconds: 1));

      // Try toggling an item.
      var row = (await list.items)[0];
      expect(await row.isToggled, isFalse);
      await row.toggle();
      expect(await row.isToggled, isTrue);

      // Check the content inside.
      expect(
        await list.description,
        equalsIgnoringWhitespace('I need help!'),
      );

      // NOT REQUIRED: We just want to slow down the test to see it.
      await Future.delayed(const Duration(seconds: 1));

      // Toggle again.
      await row.toggle();
      expect(await row.isToggled, isFalse);

      // NOT REQUIRED: We just want to slow down the test to see it.
      await Future.delayed(const Duration(seconds: 1));

      row = (await list.items)[1];
      await row.toggle();
      expect(
        await list.description,
        equalsIgnoringWhitespace('Did you read my first issue yet?'),
      );
    });
  });
}

class MockGithubService extends Mock implements GithubService {}

class IssueListPO {
  final Element _root;

  IssueListPO(this._root);

  Element get _progressBar => _root.querySelector('material-progress');

  Future<List<IssueItemPO>> _items() async => _root
      .querySelectorAll('.github-issue')
      .map((e) => IssueItemPO(e))
      .toList();

  Element get _expansion => _root.querySelector('.expansion');

  /// Whether the progress bar is visible.
  Future<bool> get isLoading async => _progressBar != null;

  /// Items in the table.
  Future<List<IssueItemPO>> get items => _items();

  /// Visible description.
  Future<String> get description async => _expansion.text;
}

class IssueItemPO {
  final Element _root;

  IssueItemPO(this._root);

  Element get _toggleButton => _root.querySelector('.material-toggle');
  Element get _author => _root.querySelector('.author');
  Element get _title => _root.querySelector('.title');

  /// Author.
  Future<String> get author async => _author.text;

  /// Title
  Future<String> get title async => _title.text;

  /// Whether the button is toggled.
  Future<bool> get isToggled async => _toggleButton.classes.contains('checked');

  /// Toggle the button.
  Future<void> toggle() async => _toggleButton.click();
}
