<!-- NOTE: We do not use 80 characters here, it is unreasonable to format. -->

Our [issue labels](https://github.com/dart-lang/angular/labels):

## Areas

Issues that only effect a specific part of the framework.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`area: analysis`][a1]            | (WIP)                                                                            |
| [`area: ast`][a2]                 | Occurs in `package:angular_ast`                                                  |
| [`area: compiler`][a3]            | Occurs in `package:angular_compiler` _or_ the compiler sub-parts of the main     |
|                                     package. In general, anything that occurs at _compile-time_ should be assigned   |
|                                     this label.                                                                      |
| [`area: forms`][a4]               | Occurs in `package:angular_forms`                                                |
| [`area: router`][a5]              | Occurs in `package:angular_router`                                               |
| [`area: runtime`][a6]             | Occurs in the main package (`package:angular`). In general anything that occurs  |
|                                     at runtime that is not part of one of the other _area_ labels should be assigned |
|                                     this label.
| [`area: test`][a7]                | Occurs in `package:angular_test` or in our own test suites.                      |

[a1]: https://github.com/dart-lang/angular/labels/area%3A%20analysis
[a2]: https://github.com/dart-lang/angular/labels/area%3A%20ast
[a3]: https://github.com/dart-lang/angular/labels/area%3A%20compiler
[a4]: https://github.com/dart-lang/angular/labels/area%3A%20forms
[a5]: https://github.com/dart-lang/angular/labels/area%3A%20router
[a6]: https://github.com/dart-lang/angular/labels/area%3A%20runtime
[a7]: https://github.com/dart-lang/angular/labels/area%3A%20test

## Organization

Issues that are specifically tagged in order to track relevance to the team.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`breaking change`][o1]           | This issue, if implemented, would be a breaking change to its respective _area_. |
| [`chore`][o2]                     | This issue requires internal re-organization, grunge work (not a feature).       |
| [`documentation`][o3]             | This issue requires documentation fixes or changes to close.                     |
| [`migrate internal users`][o4]    | This issue requires a non-trivial amount of migration of internal users in order |
|                                     to close, which is common for some (not all) _breaking changes_.                 |
| [`needs review`][o5]              | This issue requires a closer review by the team or other Dart team members.      |
| [`new feature`][o6]               | This issue represents a new feature or addition.                                 |
| [`priority`][o7]                  | This is a high priority issue, that should be resolved ASAP.                     |
| [`release blocker`][o8]           | This issue, if not resolved, would block the next stable release.                |

[o1]: https://github.com/dart-lang/angular/labels/%E2%9B%91%20breaking%20change
[o2]: https://github.com/dart-lang/angular/labels/%E2%99%BB%EF%B8%8F%20%20%20chore
[o3]: https://github.com/dart-lang/angular/labels/%E2%9C%8F%20documentation
[o4]: https://github.com/dart-lang/angular/labels/%E2%98%95%20migrate%20internal%20users
[o5]: https://github.com/dart-lang/angular/labels/%E2%9C%8D%EF%B8%8F%20%20needs%20review
[o6]: https://github.com/dart-lang/angular/labels/%E2%9A%A1new%20feature
[o7]: https://github.com/dart-lang/angular/labels/%E2%9A%A0%20PRIORITY
[o8]: https://github.com/dart-lang/angular/labels/%E2%98%A0%EF%B8%8F%20%20release%20blocker

## Resolution

Issues explaining why something was closed when it is non-obvious.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`resolution: as intended`][r1]   | This issue was closed because it is working as intended by the team.             |
| [`resolution: duplicate`][r2]     | This issue was closed because it is a duplicate of another issue.                |
| [`resolution: not planned`][r3]   | This issue was closed because the work required is not planned.                  |
| [`resolution: on hold`][r4]       | This issue is temporarily closed and may be revisited in the future.             |

[r1]: https://github.com/dart-lang/angular/labels/resolution%3A%20as%20intended
[r2]: https://github.com/dart-lang/angular/labels/resolution%3A%20duplicate
[r3]: https://github.com/dart-lang/angular/labels/resolution%3A%20not%20planned
[r4]: https://github.com/dart-lang/angular/labels/resolution%3A%20on%20hold

## States

Issues explaining why progress on this issue appears to stall.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`state: blocked`][s1]            | Progress on this issue has stalled because of another issue or dependency.       |
| [`state: merging`][s2]            | This pull request is being merged back into the main branch internally.          |
| [`state: needs info`][s3]         | Progress on this issue has stalled because of lack of information from the user. |
| [`state: syncing`][s4]            | This pull request is being synced back into GitHub from the internal branch.     |

[s1]: https://github.com/dart-lang/angular/labels/%E2%9B%94%20state%3A%20blocked
[s2]: https://github.com/dart-lang/angular/labels/%E2%A4%B5%20state%3A%20merging
[s3]: https://github.com/dart-lang/angular/labels/%E2%9B%B3%20state%3A%20needs%20info
[s4]: https://github.com/dart-lang/angular/labels/%E2%8C%9B%20state%3A%20syncing

## Dependencies

Issues highlighting what external dependencies are causing this issue.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`dependency: analyzer`][d1]      | Progress on this issue requires `package:analyzer` changes or input.             |
| [`dependency: build`][d2]         | Progress on this issue requires `package:build_*` changes or input.              |
| [`dependency: dart`][d3]          | Progress on this issue requires Dart SDK changes or input.                       |
| [`dependency: test`][d4]          | Progress on this issue requires `package:test_*` changes or input.               |

[d1]: https://github.com/dart-lang/angular/labels/%E2%9C%89%20dependency%3A%20analyzer
[d2]: https://github.com/dart-lang/angular/labels/%E2%9C%89%20dependency%3A%20build
[d3]: https://github.com/dart-lang/angular/labels/%E2%9C%89%20dependency%3A%20dart
[d4]: https://github.com/dart-lang/angular/labels/%E2%9C%89%20dependency%3A%20test


## Misc

Other labels that don't fit in above.

| Label                             | Description                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------- |
| [`experience: dev cycle`][m1]     | Effects the development cycle of users.                                          |
| [`experience: new user`][m2]      | Effects the experience of a new user to AngularDart or Dart.                     |
| [`feedback: discussion`][m3]      | This issue is centered around discussion of a topic.                             |
| [`feedback: rfc`][m4]             | This issue is a _proposal_ for large-ish changes.                                |
| [`good first issue`][m5]          | This issue would be great for first-time contributors!                           |
| [`problem: bug`][m6]              | There is a bug in the framework.                                                 |
| [`problem: perf`][m7]             | There are performance issues in the framework.                                   |
| [`question`][m8]                  | This is just a question.                                                         |

[m1]: https://github.com/dart-lang/angular/labels/%E2%9B%88%20experience%3A%20dev%20cycle
[m2]: https://github.com/dart-lang/angular/labels/%E2%9B%88%20experience%3A%20new%20user
[m3]: https://github.com/dart-lang/angular/labels/%E2%9B%B9%20feedback%3A%20discussion
[m4]: https://github.com/dart-lang/angular/labels/%E2%9B%B9%20feedback%3A%20rfc
[m5]: https://github.com/dart-lang/angular/labels/good%20first%20issue
[m6]: https://github.com/dart-lang/angular/labels/%E2%98%84%20problem%3A%20bug
[m7]: https://github.com/dart-lang/angular/labels/%E2%9A%94%20problem%3A%20perf
[m8]: https://github.com/dart-lang/angular/labels/question