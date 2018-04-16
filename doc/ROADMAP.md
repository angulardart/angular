# High Level Roadmap

This is a strawman development plan for 2017. AngularDart is currently used in
production by many large Google projects, and above all we consider *stability*,
*performance*, and *productivity* our core features.

> A note on the relationship to the *Angular JS/TS* project. While we
> communicate and share design and performance notes and keep the two versions
> as close as possible, we will at times diverge to serve the Dart community
> better rather than have identical features or APIs. At this time, we are
> developing a new dependency injection (DI) and component API based on Dagger2
> that will take advantage of Dart's strong static typing and lexical scoping.

View our [milestones][] for the most up-to-date information.

[milestones]: https://github.com/dart-lang/angular2/milestones

## Performance

*   Compilation emits idiomatic and performant Dart code with static types.
*   Change detection is cheap by default, and moving towards a reactive model.
*   Avoids checking values that are immutable or constant literals.
*   Most hooks into the framework feel idiomatic and are lightweight.

## Code Size

*   Dart's [tree-shaking][] removes features not used by all applications.
*   Static dependency injection prunes providers not used at runtime.
*   Building in "release mode" removes developer or debug-only code paths.
*   Allow easy code-splitting (deferred loading) with and without using a
    router.
*   AngularDart is suitable as a framework for a [progressive web app][pwa].

[tree-shaking]: https://webdev.dartlang.org/tools/dart2js#helping-dart2js-generate-better-code
[pwa]: https://developers.google.com/web/progressive-web-apps/

## Productivity

*   Supports the [DartDevCompiler (DDC)][ddc] and [strong mode][strong].
*   Supports lifecycle event inheritence (i.e. `NgOnDestroy` in a super class).
*   Supports inheriting `@Input` and `@Output` annotations across super classes.
*   IntelliJ/Analysis server plugin for linting and auto-complete.

## Other Priorities

*   A "batteries included" testing framework, i.e.
    [`angular_test`][angular_test].
*   A single repository for 1st-party AngularDart packages.
*   Make it easier to accept external contributions, and be more transparent.

[ddc]: https://github.com/dart-lang/sdk/tree/master/pkg/dev_compiler
[strong]: https://www.dartlang.org/guides/language/sound-dart
[angular_test]: https://pub.dartlang.org/packages/angular_test
