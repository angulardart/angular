# High Level Roadmap

This is a strawman development plan for 2016. Angular Dart is
currently used in production by many large Google projects, and above all we
consider *stability*, *performance*, and *productivity* our core features.

> A note on the relationship to the *Angular 2 JS/TS* project. While we
> communicate and share design and performance notes and keep the two versions
> as close as possible, we will at times diverge to serve the Dart community 
> better rather than have identical features or APIs. At this time, we are 
> developing a new dependency injection (DI) and component API based on Dagger2 
> that will take advantage of Dart's strong static typing and lexical scoping.

## Performance

- Optimize the Angular Dart compiler to emit idiomatic Dart code (or as close to
  it as possible).
- Optimize change detection to be cheaper and start moving towards a reactive
  model similar to Flutter where only parts of the component tree are
  checked for updates.
  - Rewrite `*ngFor` to cause less memory and CPU pressure
  - Understand `const/final` bindings, and only check once versus every cycle
- Optimize both browser and component events to be lighterweight.
- Generate more optimized templates that use static types to build smarter code.

## Code Size

- Static dependency injection friendly to tree-shaking
- Update the compiler to emit better "release-mode" code without debugging paths
- Update `*ngIf` directive to be cheaper when there are no scope implications.

## Productivity

- Formally support Dart DDC and [strong mode](https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md)/)
  (instant refresh in every browser).
- Generate i18n helper code
- Use static and top-level methods/getters in templates
- More clear, early and understandable warnings at compile-time versus runtime

## Other Plans

We hope to have more about material components, router, forms API and a new
testing story that uses code generation (like production apps) published soon.
