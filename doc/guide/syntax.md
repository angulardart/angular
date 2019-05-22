# Template Syntax

go/angular-dart/guide/syntax

[TOC]

<!--*
# Document freshness: For more information, see go/fresh-source.
freshness: { owner: 'matanl' reviewed: '2019-05-20' }
*-->

AngularDart templates are written in a _variant_ of HTML. Most HTML is valid
AngularDart, with some exceptions (for example, only double quotes `"` are
accepted for wrapping values of elements).

## Elements

### Static HTML

AngularDart supports any built-in HTML element:

```html
<button>An example of an HTML Element</button>
```

Or a registered [web component](https://developers.google.com/web/fundamentals/web-components/customelements):

```html
<social-favicon></social-favicon>
```

<!-- TODO: Add Dynamic HTML/Link To Security? -->

### Components

HTML tags that are recognized by Angular are automatically used as components:

```dart
@Component(
  selector: 'example-app',
  template: '<coffee-machine></coffee-machine>',
  directives: [CoffeeMachineComponent],
)
class ExampleApp {}

@Component(
  selector: 'coffee-machine',
  template: '...',
)
class CoffeeMachineComponent {}
```

### Directives

It's also possible to use a _directive_ whose selector may be defined using a
subset of the CSS selector syntax.

| Supported selectors   | Example     |
| --------------------- | ----------- |
| Type (or element)     | `foo`       |
| Attribute             | `[bar]`     |
| Class                 | `.baz`      |
| `:not()` pseudo-class | `:not(qux)` |

For example here is creation and usage of a directive with an `[attribute]`
selector:

```dart
@Component(
  selector: 'example-app',
  template: '''
    <button auto-id>...</button>
  ''',
  directives: [AutoIdDirective],
)
class ExampleApp {}

@Directive(
  selector: '[auto-id]',
)
class AutoIdDirective {
  static var _nextId = 0;
  
  // Sets the attribute "auto-id" to the next auto-incrementing number.
  //
  // (Note this is a sample only and not a best practice)
  @HostBinding('attr.auto-id')
  final int assignId = ++_nextId;
}
```

## Attributes

### Static Attributes

AngularDart supports simple static attributes (that do not change):

```html
<img alt="A beautiful Sunset" />
```

Attributes without values are also supported:

```html
<button disabled>Delete</button>
```

### Dynamic Attributes

It's also possible to set a value at runtime using `[attr.name]="value"`,
where value is an [expression](#expressions) evaluated at runtime:

```html
<img [attr.alt]="caption" />
```

Or using string interpolation:

```html
<img alt="A picture of {{title}}" />
```

This is equivalent to binding to `'A picture of ${component.title}'` in Dart.

### Conditional Attributes

To add or remove an attribute based on an [expression](#expressions)
evaluating to true/false you may use the `.if` suffix (i.e.
`[attr.name.if]="boolean"`):

```html
<button [attr.disabled.if]="!canSave">Save</button>
```

> NOTE: For historical reasons, it is also possible to use `null` to remove an
> attribute (it is **strongly preferred** to use the `[attr.name.if]` syntax
> instead, however):
>
> ```html
> <button [attr.disabled]="canSave ? null : true">Save</button>
> ```
>
> This feature may be removed in a future version of Angular.

## Classes and Styles

### Static Classes

AngularDart supports simple static CSS class names (that do not change):

```html
<div class="highlight">"The night is dark and full of terrors."</div>
```

### Conditional Classes

Add or remove CSS classes based on a boolean [expression](#expressions)
with `[class.*]`:

```html
<div [class.highlight]="isHighlighted"
     [class.emphasized]="isBookmarked">
 ...
</div>
```

### Dynamic Classes

It's also possible to assign CSS classes entirely at runtime:

```html
<div [class]="cssClasses">"Times may change, but men do not."</div>
```

In this case, `cssClasses` is expected to be a Dart `String` (or an
[expression](#expressions) that results in a `String`), with spaces as a
delimiter if you intend to assign multiple CSS classes:

```dart
class Example {
  // Adds the CSS classes "highlight", "quote", and "bookmark".
  final cssClasses = 'highlight quote bookmark';
}
```

> NOTE: For historic reasons, the following syntax also works:
>
> ```html
> <div [attr.class]="cssClasses">...</div>
> <div class="{{cssClasses}}">...</div>
> ```
>
> When in doubt, prefer `[class]="..."` for long-term compatibility.

> WARNING: Dynamic classes can be very brittle.
>
> If `[class]="..."` (or a similar syntax) is used to dynamically assign CSS
> classes, then no other class assignment can be used on the provided element
> as Angular does not guarantee they will all be respected.
>
> For advanced use cases where you need to add dynamic CSS classes at runtime
> _and_ other CSS classes (either static or conditional), use the `NgClass`
> directive instead:
>
> ```html
> <div class="static" [ngClass]="cssClasses">...</div>
> ```

### Static Styles

AngularDart supports simple static inline styles:

```html
<div style="color: #ff0000">Error</div>
```

### Dynamic Styles

It's also possible to set a value at runtime using `[style.name]="value"`:

```html
<div [style.color]="message.color">{{message.text}}</div>
```

A suffix can be added in order to automatically add it to the result:

```html
<div [style.width.px]="progressBarWidth"></div>
```

## Events

Listen to HTML events or [custom events](events.md) using `(name)="callback"`:

```html
<button (click)="onClick()"></button>
```

```html
<coffee-machine (depleted)="soundTheAlarm()"></coffee-machine>
```

You may pass an event parameter, if available, by referencing `$event`:

```html
<!-- Passes the event object to "onClick" -->
<button (click)="onClick($event)"></button>
```

It's also possible to omit the `(...)` and have it be inferred automatically:

```html
<button (click)="onClick"></button>
```

It is also valid to write [simple expressions](#expressions) instead:

```html
<button (click)="noteState = NoteState.draft">Save as Draft</button>
```

### Key Events

When using either `(keyup)` or `(keydown)`, you may filter based on the key:

```html
<input (keyup.enter)="saveEntry()" />
```

It is also possible to combine these filters with modifier key(s):

```html
<textarea (keyup.ctrl.s)="saveEntry()" />
```

> NOTE: There is currently a limited number of keys supported.
>
> See `lib/src/runtime/dom_events.dart` in the codebase for details.

> WARNING: This syntax is explicitly not supported for `(keypress)` which is now
> deprecated.

## Properties

Assign a value to a property of an HTML element or an `@Input()` of a component:

```html
<img [src]="photoUrl" />

<coffee-machine [decaf]="isDecaf"></coffee-machine>
```

## Structural Directives

Use _structural_ directives (directives prefixed with a `*`) to control the
structure of the DOM.

For example, the built-in `NgIf` directive creates and destroys content based on
an [expression](#expressions) evaluating to `true` or `false`:

```html
<section *ngIf="isLoggedIn">
  Welcome back {{user}}!
</section>
```

The built-in directive `NgFor` iterates over a Dart `Iterable` repeating DOM:

```html
<ul>
  <li *ngFor="let dog of dogs">
    {{dog.name}} ({{dog.age}} year(s) old)
  </li>
</ul>
```

> NOTE: This syntax for ngFor may seem strange.
>
> Originally there was a shared code-base between both Angular TypeScript and
> Dart, and we decided for backwards compatibility to keep "let" even though it
> is not a keyword in Dart. This may change in the future.

When you see a `*`, it is syntactic sugar for an [embedded template](#embedded-templates):

```html
<!-- These two blocks are identical -->

<section *ngIf="isLoggedIn">
  Welcome back {{user}}!
</section>

<template [ngIf]="isLoggedIn">
  <section>
    Welcome back {{user}}!
  </section>
</template>
```

You can also use `<ng-container>` to host a structural directive, without
introducing a superfluous DOM node (identical to the above):

```html
<ng-container *ngIf="isLoggedIn">
  <section>
    Welcome back {{user}}!
  </section>
</ng-container>
```

This avoids having to write `<template>`, which can be confusing, in particular
with `*ngFor`, which relies on the `*`-syntax to desugar into a more complicated
set of elements and properties.

## References

AngularDart supports tagging a component or element with `#name`:

```html
<coffee-machine #machine></coffee-machine>
```

It is then possible to use that name as an identifier in expressions:

```html
<button (click)="reloadMachine(machine)">Reload</button>
```

> WARNING: Tagged references are global to the entire template and only
> available when the element is active (i.e. not destroyed by something like
> `*ngIf` or `*ngFor`).

## Embedded Templates

The `<template>` tag can be used to create lazily instantiated/loaded content:

```html
<template #sayHello>
  Hello {{name}}!
</template>

<some-component [template]="sayHello"></some-component>
```

In the above, we are declaring a reference to a `TemplateRef` and passing it as
an [input](#properties) to a component.

## Projected Content

The `<ng-content>` tag can mark a part of the template as accepting children
from its parent. This is the normal way to create reusable components that
don't necessarily know their children:

```html
<div class="wooden-frame">
  <ng-content></ng-content>
</div>
```

A parent would then use this component like so:

```html
<picture-frame>
  <img src="my-dog.jpg" />
</picture-frame>
```

In this example, the `<img/>` would be rendered at the location of the
`<ng-content>` slot in the `<picture-frame>`.

It is also possible to use the `selector` property to project by CSS matching:

```html
<header>
  <ng-content select=".header"></ng-content>
</header>
<footer>
  <ng-content select=".footer"></ng-content>
</footer>
```

> WARNING: The full set of CSS selection is not available.

<!-- TODO: Expand what is available. -->

## Two-Way Bindings

TBD

## Text Interpolation

TBD

## Expressions

TBD
