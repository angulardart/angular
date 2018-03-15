import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular/security.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:ng_bootstrap/ng_bootstrap.dart';

import 'api.dart';

@Component(
  selector: 'issue-list',
  directives: const [
    bsDirectives,
    coreDirectives,
    formDirectives,
    IssueBodyComponent,
    IssueTitleComponent,
  ],
  styleUrls: const ['src/ui/issue_list.css'],
  templateUrl: 'src/ui/issue_list.html',
)
class IssueListComponent implements OnInit {
  final GithubService _github;

  GithubIssue showDescriptionFor;
  List<GithubIssue> issues = const [];
  int progress = 0;

  Timer _loadingTimer;

  IssueListComponent(this._github) {
    _loadingTimer = new Timer.periodic(const Duration(milliseconds: 50), (_) {
      progress += 10;
      if (progress > 100) {
        progress = 0;
      }
    });
  }

  bool get isLoading => issues.isEmpty;

  @override
  ngOnInit() async {
    issues = await _github.getIssues().toList();
    _loadingTimer.cancel();
  }

  void toggleDescription(GithubIssue issue) {
    if (showDescriptionFor == issue) {
      showDescriptionFor = null;
    } else {
      showDescriptionFor = issue;
    }
  }
}

/// Renders [GithubIssue.description].
@Component(
  selector: 'issue-description',
  template: r'''
    <div [innerHtml]="safeHtml"></div>
  ''',
)
class IssueBodyComponent {
  final DomSanitizationService _sanitizer;

  GithubIssue _issue;
  SafeHtml _safeHtml;

  IssueBodyComponent(this._sanitizer);

  @Input()
  set issue(GithubIssue issue) {
    _safeHtml = _sanitizer.bypassSecurityTrustHtml(
      md.markdownToHtml(issue.description),
    );
  }

  SafeHtml get safeHtml => _safeHtml;
}

/// Renders [GithubIssue.title].
@Component(
  selector: 'issue-title',
  styles: const [
    r'''
    a {
      display: block;
    }
  '''
  ],
  template: r'''
    <a [href]="safeUrl">{{issue.title}}</a>
  ''',
)
class IssueTitleComponent {
  final DomSanitizationService _sanitizer;

  GithubIssue _issue;
  SafeUrl _safeUrl;

  IssueTitleComponent(this._sanitizer);

  /// Github issue model.
  GithubIssue get issue => _issue;

  @Input()
  set issue(GithubIssue issue) {
    _issue = issue;
    _safeUrl = _sanitizer.bypassSecurityTrustUrl(issue.url.toString());
  }

  /// Github issue URL.
  SafeUrl get safeUrl => _safeUrl;
}
