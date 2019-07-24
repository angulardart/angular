## 1.0.0-alpha+1

*   Maintenance release to support Angular 6.0-alpha+1.

## 1.0.0-alpha

*  The Angular analyzer plugin has moved into the core angular repo, and will be
   developed by the Angular team going forward.

## 0.0.17+6

*   Fixed an issue where an unnecessary navigation range was added to HTML
    files.
*   Fixed an issue where navigation would be delayed in IntelliJ and other IDEs
    that use the notification pattern for navigation.
*   Change analyzer API for forwards compatibility with part files. The old API
    could have caused out-of-date errors to be cached for a file. The new API,
    however, introduces extra asynchrony. Manual testing seemed to show
    everything working properly however this _may_ cause race conditions or hurt
    performance.

## 0.0.17+5

*   Fixed an issue where a corrupt URI would crash the plugin on windows.

## 0.0.17+4

*   Refactored how non-angular expressions (`new`, `+=`, `..`, etc.) are
    detected.
*   Refactored how `exports` are handled in a fairly major way.
*   Typecheck the results and input of pipe expressions and the existence of a
    matching pipe. Optional arguments are not yet typechecked.
*   Add typechecking support for `[attr.foo.if]`, and ensure that a
    corresponding `[attr.foo]` binding exists.
*   Fixed issues with `<ng-container>`, which resulted in the inner content
    simply being ignored instead of being validated (and also caused some
    problems with finding inner `<ng-content>` tags).
*   More checks for rejected operators like `+=`, `++` other unary operators and
    compound assignments.
*   Named arguments are no longer reported as disallowed as angular now supports
    them.

## 0.0.17+3

*   Fixed an issue where a cast error from certain top-level getters would crash
    the plugin.

## 0.0.17+2

*   Fixed an issue where pipes with a dynamic type optional parameter would
    crash the plugin.

## 0.0.17+1

*   Fixed an issue where standard HTML events weren't recognized due to changes
    made to dart:html sources on newer SDKs.

## 0.0.17

*   More dart 2 runtime support.
*   Upgrade package:analyzer to support newest dart semantics.

## 0.0.16

*   Fixed an issue where you couldn't reference a static member of the component
    class without a warning.
*   Support dart 2 runtimes
*   Better error message for when attribute selectors have an operator but no
    value.
*   In previous versions, the `x*=y` selector was working incorrectly. It
    matched attributes whose *names began with* `x` and optionally contained a
    value `y`. This has been fixed to do the correct thing: match an attribute
    of name `x` when the value contains `y`.
*   Support '^=' css selector syntax.
*   Upgrade package:analyzer to support newest dart semantics.

## 0.0.15

*   Refactored attribute autocompletion
*   Fixed a bug where pipes that inherited transform() got flagged.
*   Fixed a bug where parts' templateUrls should be relative to the parts'
    library and not the part itself.
*   Added support for === operator.

Some larger items:

### Newer options config

The required config has been changed in a backwards-compatible way. However,
note that while 0.0.14's config works for 0.0.15 users, the reverse is not true.

Specifically, we no longer require `enabled: true`, and we are moving from
configuring the plugin inside `analyzer`, to having its own top level. This
solves a number of problems related to finding, merging, or modifying config,
with a potentially large number of methods of loading the plugin.

Old:

```yaml
analyzer:
  plugins:
    angular:
      enabled: true
      custom_tag_names:
        - foo
        - bar
```

New:

```yaml
analyzer:
  plugins:
    - angular

angular:
  custom_tag_names:
    - foo
    - bar
```

This is encouraged for users on more recent versions than 0.0.14. Support for
the old system will likely first be flagged within the dart analyzer itself, and
then dropped from our plugin a while after that.

## 0.0.14

*   Fixed issues with locating sources in Windows
*   Fixed an order-of-operations bug where getting completions before errors
    suppressed the subsequent error notification.
*   Fixed a performance problem due to new navigation features, and correctness
    issue where local unsaved changes were used in html navigation line/offset
    info.
*   Fixed crashes in latest IntelliJ due to new navigation features
*   Upgrade package:analyzer to support newest dart semantics.
*   Fixed crash autocompleting before a comment
*   Upgraded package:analyzer for latest dart semantics + bug fixes
*   Upgraded package:analyzer_plugin for fix with autocompleting members on
    dynamic values

## 0.0.13

*   Fixed a memory leak cause by a stream with no listener
*   Support FutureOr-typed inputs
*   Upgrade package:analyzer to support newest dart semantics.

## 0.0.12

*   Support `(focusin)` and `(focusout)` events.
*   Fix crash autocompleting an input in a star-attr when the input name matches
    the star attr text exactly.
*   Bugfix regarding quotes in attribute selector values. For example, `[x="y"]`
    now correctly expects the value `y` for some attr `x`.
*   Allow (and suggest) `List` instead of `QueryList`. Note, QueryList is still
    supported, for now.

Some larger items:

### Allow custom events with custom types to be specified. (#485)

Example syntax:

```yaml
  analyzer:
    plugins:
      angular:
        enabled: true
        custom_events:
          doodle:
            type: DoodleEvent
            path: 'package:doodle/events.dart'
          poodle:
            type: PoodleEvent
            path: 'package:doodle/events.dart'
```

### Add new options for ContentChild(ren) in prep for deprecating ElementRef;

Accept (for the moment) ElementRef, Element, and HtmlElement (the latter two
being from dart:html).

Ensure HtmlElement and Element use read: x when @ContentChild('foo'), and check
assignability for the read: type.

Note, we currently don't differentiate SVG and HTML, so we accept either type
for either case at the moment.

## 0.0.11

*   *@View no longer supported.*
*   Clearer error for templates that are included from unconventional
    components. Usually, this is from test components where this occurs.
*   Allow `directives: VARIABLE` in addition to `directives: const [VARIABLE]`.
*   Functional Directive support
*   Handle optional parameters in pipes
*   Change "overcomplicated templates" error (templates set to const strings
    that are calculated rather than defined full-form, making error ranges
    difficult or impossible to provide) to a hint from an error.
*   Expect angular classes to be in `package:angular` (though still look at
    `package:angular2` if that is missing).
*   Check that reductions (ie, `(keyup.space)`) are only on key events.
*   Support angular security, which otherwise produces assignment errors.
*   *Plugin loading mechanism changed.*
*   Support `<audio>` tag.
*   Handle directive inheritance.

Some larger items:

### Allow custom tag names

Example syntax:

```yaml
  analyzer:
    plugins:
      angular:
        enabled: true
        custom_tag_names:
          - foo
          - bar
          - baz
```

Most errors related to custom tags are suppressed, because custom tags are often
handled by other frameworks (ie, polymer).

# 0.0.10

Started changelog.
