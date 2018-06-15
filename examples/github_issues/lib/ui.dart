import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/security.dart';
import 'package:angular_components/material_progress/material_progress.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:markdown/markdown.dart' as md;

import 'api.dart';

@Component(
  selector: 'issue-list',
  directives: [
    NgFor,
    NgIf,
    IssueBodyComponent,
    IssueTitleComponent,
    MaterialProgressComponent,
    MaterialToggleComponent,
  ],
  styleUrls: ['src/ui/issue_list.scss.css'],
  templateUrl: 'src/ui/issue_list.html',
)
class IssueListComponent implements OnInit {
  final GithubService _github;

  GithubIssue showDescriptionFor;
  List<GithubIssue> issues = const [];
  int progress = 0;

  Timer _loadingTimer;

  IssueListComponent(this._github) {
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
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
  styles: [
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
