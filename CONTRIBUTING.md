## <a name="question"></a> Got a Question or Problem?

If you have questions about how to *use* Angular, please direct them to the
[Google Group][angular-group] discussion list or [StackOverflow][stackoverflow].
Please note that Angular 2 is still in early developer preview, and the core
team's capacity to answer usage questions is limited.

## <a name="issue"></a> Found an Issue?
If you find a bug in the source code or a mistake in the documentation, you can
help us by [submitting an issue](#submit-issue) to our
[GitHub Repository][github]. Even better, you can
[submit a Pull Request](#submit-pr) with a fix.

## <a name="feature"></a> Want a Feature?
You can *request* a new feature by [submitting an issue](#submit-issue) to our
[GitHub Repository][github].

If you would like to *implement* a new feature, please submit an issue with a
proposal for your work first, to be sure that we can use it.

Angular 2 is in developer preview and we are not ready to accept major
contributions ahead of the full release. Please consider what kind of change it
is:

* For a **Major Feature**, first open an issue and outline your proposal so that
it can be discussed.
This will also allow us to better coordinate our efforts, prevent duplication of
work, and help you to craft the change so that it is successfully accepted into
the project.
* **Small Features** can be crafted and directly
[submitted as a Pull Request](#submit-pr).

## <a name="submit"></a> Submission Guidelines

### <a name="submit-issue"></a> Submitting an Issue
Before you submit an issue, search the archive, maybe your question was already
answered.

If your issue appears to be a bug, and hasn't been reported, open a new issue.
Help us to maximize the effort we can spend fixing issues and adding new
features, by not reporting duplicate issues.  Providing the following
information will increase the chances of your issue being dealt with quickly:

* **Overview of the Issue** - if an error is being thrown a non-minified stack
  trace helps
* **Angular Version** - what version of Angular is affected
  (e.g. 2.0.0-alpha.53)
* **Motivation or Use Case** - explain what are you trying to do and why the
  current behavior is a bug for you
* **Browsers and Operating System** - is this a problem with all browsers?
* **Reproduce the Error** - provide an unambiguous set of steps
* **Related Issues** - has a similar issue been reported before?
* **Suggest a Fix** - if you can't fix the bug yourself, perhaps you can point
  to what might be causing the problem (line of code or commit)

You can file new issues by providing the above information
[here][github-new-issue].

### <a name="submit-pr"></a> Submitting a Pull Request (PR)
Before you submit your Pull Request (PR) consider the following guidelines:

* Search [GitHub][github-pulls] for an open or
  closed PR that relates to your submission. You don't want to duplicate effort.
* Please sign our [Contributor License Agreement (CLA)](#cla) before sending
  PRs. We cannot accept code without this.

As [mentioned above](#feature), Pull Request should generally be small in scope.
Anything more complex should start as an issue instead. Some examples of types
of pull requests that are immediately helpful:

* Fixing a bug without changing the public API.
* Fixing or improving documentation.

#### Merging pull requests

Due to the fact that AngularDart is developed as a subset of Google's internal
codebase (which is automatically synced to the public GitHub repository), we are
unable to merge pull requests directly into the master branch. Instead, once a
pull request is ready for merging, we'll make the appropriate changes in the
internal codebase and, when the change is synced out, give the pull request
author credit for the commit.

## <a name="cla"></a> Signing the CLA

Please sign our Contributor License Agreement (CLA) before sending pull
requests. For any code changes to be accepted, the CLA must be signed. It's a
quick process, we promise!

* For individuals we have a [simple click-through form][individual-cla].
* For corporations we'll need you to
  [print, sign and one of scan+email, fax or mail the form][corporate-cla].

[angular-group]: https://groups.google.com/a/dartlang.org/forum/#!forum/angular2
[corporate-cla]: http://code.google.com/legal/corporate-cla-v1.0.html
[github]: https://github.com/dart-lang/angular2
[github-new-issue]: https://github.com/dart-lang/angular2/issues/new
[github-pulls]: https://github.com/dart-lang/angular2/pulls
[individual-cla]: http://code.google.com/legal/individual-cla-v1.0.html
[stackoverflow]: https://stackoverflow.com/questions/tagged/angular-dart
