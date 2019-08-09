# Imperative Component Loading


AngularDart performs best when a template and application tree is statically
defined. However, some smaller parts of an application might need to, at
runtime, add new components. This guide shows you how to use `ComponentLoader`
to add components imperatively, and how to migrate from `DynamicComponentLoader`
(renamed to `SlowComponentLoader`), the original API.

## Background

Historically, AngularDart supported loading components based on the class
[`Type`](https://api.dartlang.org/stable/dart-core/Type-class.html), which was
looked up in a _reflective_ manner. Basically, in the code generation step, we
generated a `Map` that looks like this:

```dart
final componentMapping = {
  MyComponent: MyComponentNgFactory,
};
```

What this also means is that Dart's _tree shaking_ is impacted (negatively) as
code paths to load _any_ `@Component` in your transitive dependency graph are
retained. Future versions of AngularDart will attempt to remove this behavior,
but that means `Type` can no longer be used to load components.

What you _can_ use is what is called a
[`ComponentFactory`](https://webdev.dartlang.org/api/angular/angular/ComponentFactory-class),
a generated object that represents a handle to imperatively creating the
component `class` it was generated from. The new `ComponentLoader` API accepts
these `ComponentFactory` instances instead of `Type`.

Imagine you have an `@Component()` annotated class called `FooComponent` in the
file `lib/foo.dart`:

```dart
@Component(selector: 'foo', template: '')
class FooComponent {}
```

To get a handle to its `ComponentFactory`, import `lib/foo.template.dart`:

```dart
// Importing generated files with a prefix is not required but is nice to do.
import 'foo.template.dart' as ng;

void doSomething() {
  ng.FooComponentNgFactory;
  //             ^^^^^^^^^
}
```

It's always the class _name_ with a suffix of `NgFactory`.

See [migration](#migration) below for how to migrate off using a `Type`.

## Overview

There are three ways to imperatively load a component with `ComponentLoader`:

### Load next to a location

AngularDart templates support _reserving_ areas of the DOM for imperative
component loading - you can use the `<template>` tag to create a render-free
location in the DOM, and the `#` symbol to label it. Here's a simple example:

```dart
@Component(
  selector: 'ad-view',
  template: r'''
    This component is sponsored by:
    <template #currentAd></template>
  ''',
)
class AdViewComponent {
  final ComponentLoader _loader;

  AdViewComponent(this._loader);

  @ViewChild('currentAd', read: ViewContainerRef)
  ViewContainerRef currentAd;

  @Input()
  set component(ComponentFactory component) {
    _loader.loadNextToLocation(component, currentAd);
  }
}
```

Now we can use our `<ad-view>` component to display a different Ad at runtime:

```dart
import 'example_ad_1.template.dart' as example_1;
import 'example_ad_2.template.dart' as example_2;

@Component(
  selector: 'blog-article',
  template: '<ad-view [component]="component"></ad-view>',
  directives: [
    AdViewComponent,
  ],
)
class BlogArticleComponent {
  BlogArticleComponent(AdService adService) {
    if (adService.showExample1) {
      component = example_1.Example1ComponentNgFactory;
    } else {
      component = example_2.Example2ComponentNgFactory;
    }
  }

  ComponentFactory component;
}
```

### Load next to yourself

A [_structural_
directive](https://webdev.dartlang.org/angular/guide/structural-directives) can
be created as both a directive _and_ a reserved area of the DOM for runtime
loading (and unloading). Some examples of built-in structural directives are
`*ngIf` and `*ngFor`.

Here's about the same component as above instead written as a directive:

```dart
@Directive(
  selector: '[adView]',
)
class AdViewDirective {
  final ComponentLoader _loader;

  AdViewDirective(this._loader);

  @Input()
  set adView(ComponentFactory component) {
    _loader.loadNextTo(component);
  }
}
```

```dart
import 'example_ad_1.template.dart' as example_1;
import 'example_ad_2.template.dart' as example_2;

@Component(
  selector: 'blog-article',
  template: r'''
    Blah blah blah.<br>
    This article is sponsored by:<br>
    <template [adView]="component"></template>
  ''',
  directives: [
    AdViewDirective,
  ],
)
class BlogArticleComponent {
  BlogArticleComponent(AdService adService) {
    if (adService.showExample1) {
      component = example_1.Example1ComponentNgFactory;
    } else {
      component = example_2.Example2ComponentNgFactory;
    }
  }

  ComponentFactory component;
}
```

### Using `@deferred` to lazy load components

A _simple_ option for deferred (or lazy) loading is using the `@deferred` syntax
within the HTML template. Simply place `@deferred` on any _component_ tag. The
below example will lazy load the code required to create `<expensive-comp>`:

```html
<expensive-comp @deferred></expensive-comp>
```

You can also combine `@deferred` with something like an `ngIf`, but you will
need to use a nested `ngIf`, as `@deferred` cannot be placed directly on a `*`
directive:

```html
<template [ngIf]="showExpensiveComp">
  <expensive-comp @deferred></expensive-comp>
</template>
```

### Manual lazy loading using `ComponentLoader`

If your use case requires more controlt than `@deferred` provides,
`ComponentLoader` also works great with _deferred_ loading. Here is an example
of the same component above using _deferred_ loading to load more code on
demand:

```dart
import 'example_ad_1.template.dart' deferred as example_1;
import 'example_ad_2.template.dart' deferred as example_2;

@Component(
  selector: 'blog-article',
  template: r'''
    Blah blah blah.<br>
    This article is sponsored by:<br>
    <template [adView]="component"></template>
  ''',
  directives: [
    AdViewDirective,
  ],
)
class BlogArticleComponent implements OnInit {
  final AdService _adService;

  BlogArticleComponent(this._adService);

  @override
  void ngOnInit() async {
    if (_adService.showExample1) {
      await example_1.loadLibrary();
      component = example_1.Example1ComponentNgFactory;
    } else {
      await example_2.loadLibrary();
      component = example_2.Example2ComponentNgFactory;
    }
  }

  ComponentFactory component;
}
```

If you are using `SlowComponentLoader` or `ReflectiveInjector` within your
application, you will need an additional step - calling `initReflector()`:

```dart
void ngOnInit() async {
  if (_adService.showExample1) {
    await example_1.loadLibrary();
    example_1.initReflector();
    component = example_1.Example1ComponentNgFactory;
  }
}
```

## Updating loaded components

Sometimes, you need to set inputs on a component loaded via `ComponentLoader`.
You can use `ComponentRef.update()` to trigger the appropriate Angular
lifecycles, like `AfterChanges` after running the callback.

```
@Component(selector: 'foo', template: '{{name}}')
class FooComponent implements AfterChanges {
  @Input()
  String name;

  @override
  void ngAfterChanges() {
    // This is called by ComponentRef.update().
  }
}

@Directive(selector: '[fooLoader]')
class FooLoaderDirective {
  final ComponentLoader _loader;

  FooLoaderDirective(this._loader);

  @override
  void ngOnInit() {
    var ref = _loader.loadNextTo(FooComponentNgFactory);
    ref.update((fooComponent) => fooComponent.name = 'Foo');
  }
}
```

## Migration

If you see `SlowComponentLoader` or `DynamicComponentLoader` in your app it
still will work - but it means you will not be able to opt-in to optimizations
in the future - which will be significant for larger applications or
applications using shared libraries of components that they only use few.

In most cases, it is an easy rename and importing a `.template.dart` file.

If you had code like the following:

```dart
import 'package:angular/angular.dart';

import 'foo.dart' as foo;

@Component(
  selector: 'dynamic-view',
  template: r'''
    <template #location></template>
  ''',
)
class DynamicView implements OnInit {
  final DynamicComponentLoader _loader;

  ComponentRef _componentRef;

  DynamicView(this._loader);

  @override
  ngOnInit() async {
    _componentRef = await _loader.loadNextToLocation(
        foo.FooComponent, location);
  }

  @ViewChild('location', read: ViewContainerRef)
  ViewContainerRef location;
}
```

You can change it to:

```dart
import 'package:angular/angular.dart';

import 'foo.template.dart' as foo;

@Component(
  selector: 'dynamic-view',
  template: r'''
    <template #location></template>
  ''',
)
class DynamicView implements OnInit {
  final ComponentLoader _loader;

  ComponentRef _componentRef;

  DynamicView(this._loader);

  @override
  void ngOnInit() {
    // Now synchronous.
    _componentRef = _loader.loadNextToLocation(
      foo.FooComponentNgFactory,
      location,
    );
  }

  @ViewChild('location', read: ViewContainerRef)
  ViewContainerRef location;
}
```

### Caveats

Code that is generated (i.e. in `*.template.dart`) cannot be properly analyzed
by the compiler (it's not generated yet!), which means code like this will not
work:

```dart
const provider = ValueProvider.forToken(someToken, FooComponentNgFactory);
```

You can work around this by using `useFactory`:

```dart
const provider = FactoryProvider.forToken(someToken, getNgFactory);

@Injectable()
ComponentFactory getNgFactory() => FooComponentNgFactory;
```
