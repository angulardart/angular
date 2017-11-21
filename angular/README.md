![AngularDart](https://raw.githubusercontent.com/dart-lang/logos/master/logos_and_wordmarks/angulardart-logo.png)

<!-- Badges -->

[![Pub Package](https://img.shields.io/pub/v/angular.svg)](https://pub.dartlang.org/packages/angular)
[![Build Status](https://travis-ci.org/dart-lang/angular.svg?branch=master)](https://travis-ci.org/dart-lang/angular)
[![Gitter](https://img.shields.io/gitter/room/dart-lang/angular.svg)](https://gitter.im/dart-lang/angular)

[AngularDart][webdev_angular] is a productive web application framework that
powers some of Google's most critical applications.
It's built on [Dart][dart_web] and used extensively by Google
[AdWords][ad_words], [AdSense][ad_sense], [Fiber][fiber],
and many more projects.

<a href="http://news.dartlang.org/2016/03/the-new-adwords-ui-uses-dart-we-asked.html">
<img src="https://2.bp.blogspot.com/-T50YZP5hlW4/Vv07k1PPVmI/AAAAAAAAM_Q/kVo8eImMOFUWLYqXg_xGzaWPvvlO7lhng/s0/adwords-dart.png" width="800" alt="Built with AngularDart">
</a>

**NOTE**: As of `angular 5.0.0-alpha+1` [`dependency_overrides`][dep_overrides] are **required**:

```yaml
dependency_overrides:
  analyzer: ^0.31.0-alpha.1
```

This is because we are starting to use and support the Dart 2.0.0 SDK, which is evolving. We expect
to no longer require overrides once we are at a beta release, but this is unlikely until sometime
in early 2018.

[dep_overrides]: https://www.dartlang.org/tools/pub/dependencies#dependency-overrides

## New to AngularDart?

Ramp up quickly with our docs, codelabs, and examples:

* Go to [Get Started][get_started] for a quick introduction to
  creating and running AngularDart web apps.

* Try the [material design codelab][codelab1], which uses the
  [`angular_components`][webdev_components]
  package for production-quality material design widgets built and used by
  Google.

* Follow the [AngularDart tutorial][tutorial] to build a
  fully working application that includes routing, HTTP networking, and more.

You may also be interested in [other codelabs][codelabs] and
a set of [community contributed tutorials][comm].

[get_started]: https://webdev.dartlang.org/guides/get-started
[codelab1]: https://codelabs.developers.google.com/codelabs/your-first-angulardart-web-app/
[tutorial]: https://webdev.dartlang.org/angular/tutorial
[codelabs]: https://webdev.dartlang.org/codelabs
[comm]: https://dart.academy/tag/angular2/
[webdev_components]: https://webdev.dartlang.org/components


## Getting AngularDart

AngularDart is available as the [`angular` package on pub][pub_angular].

> For historical reasons, this package was once called `angular2`. We have since
> dropped the 2 and are now just `angular`. If you're looking for
> version 2.x or 3.x, see the [`angular2` package][angular2].

[angular2]: https://pub.dartlang.org/packages/angular2


## Resources

 * Pub packages:
   [angular][pub_angular],
   [angular_components][pub_angular_components],
   [angular_router][pub_angular_router],
   [angular_test][pub_angular_test]
 * GitHub repo (dart-lang/angular):
   [source code](https://github.com/dart-lang/angular),
   [issues](https://github.com/dart-lang/angular/issues),
   [contributor guidelines][contribute]
 * Community/support:
   [mailing list](https://groups.google.com/a/dartlang.org/forum/#!forum/web),
   [Gitter chat room](https://gitter.im/dart-lang/angular)
 * [Logo (SVG)](https://raw.githubusercontent.com/dart-lang/logos/master/logos_and_wordmarks/angulardart-logo.svg)
 * [Documentation][webdev_angular]

[ad_sense]: http://news.dartlang.org/2016/10/google-adsense-angular-dart.html
[ad_words]: http://news.dartlang.org/2016/03/the-new-adwords-ui-uses-dart-we-asked.html
[fiber]: http://news.dartlang.org/2015/11/how-google-uses-angular-2-with-dart.html
[webdev_angular]: https://webdev.dartlang.org/angular
[dart_web]: https://webdev.dartlang.org/
[pub_angular]: https://pub.dartlang.org/packages/angular
[pub_angular_components]: https://pub.dartlang.org/packages/angular_components
[pub_angular_router]: https://pub.dartlang.org/packages/angular_router
[pub_angular_test]: https://pub.dartlang.org/packages/angular_test
[contribute]: https://github.com/dart-lang/angular/blob/master/CONTRIBUTING.md
