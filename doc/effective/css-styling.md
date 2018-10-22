# CSS Styling


AngularDart offers a variety of methods for styling your application. This
document is intended to help developers understand how and when to use these
options.

## Global styles

You may include style sheets or declarations in *index.html* just like you would
for any other web page. We refer to these as *global styles*, because they apply
to all of the components in your application.

### DO declare application-wide styles in index.html

Declare styles applicable to your entire application using a `<style>` tag in
*index.html*.

```html
<html>
  <head>
    <script defer src="main.dart.js"></script>
    <style>
      * {
        box-sizing: border-box;
      }
      body {
        background-color: #f2f2f2;
        font-family: Roboto, sans-serif;
        font-size: 16px;
      }
    </style>
  </head>
  <body></body>
</html>
```

### DO include external style sheets in index.html

If you're using a style sheet external to your project, such as one for a CSS
framework, include it using a `<link>` tag in *index.html*.

```html
<html>
  <head>
    <script defer src="main.dart.js"></script>
    <link rel="stylesheet" type="text/css" href="https://cdn.a.b.c/style.css">
  </head>
  <body></body>
</html>
```

> __NOTE:__ If the framework provides specialized instructions, you should
  follow them instead.

## Component styles

Styles can be included or declared in the component's `styleUrls` or `styles`
parameter. We refer to these as *component styles*.

```dart
@Component(
  selector: 'example',
  templateUrl: 'example_component.html',
  styleUrls: const ['example_component.css'],
)
class ExampleComponent {}
```

### Understanding style encapsulation

By default, component styles are encapsulated so that they apply only to their
component's view. Given the above example, styles in *example_component.css*
will only apply to HTML in *example_component.html*.

> __NOTE:__ Encapsulated styles won't apply to projected HTML inside an
  `<ng-content>` tag, nor dynamic HTML bound to `innerHtml`.

Encapsulation is particularly useful as your application grows in size, as it
prevent styles from one component interfering with those of another.

You can disable encapsulation if desired.

```dart
@Component(
  selector: 'example',
  templateUrl: 'example_component.html',
  stylesUrls: const ['example_component.css'],
  encapsulation: ViewEncapsulation.None,
)
class ExampleComponent {}
```

Now *example_component.css* will apply globally; however, unlike global styles
included in *index.html*, this won't be injected into the DOM until the first
time `ExampleComponent` is rendered.

### DO use component styles where applicable

Any styles that are component specific should be included as component styles.

### DO reuse styles in shared style sheets

If you have styles common to multiple components, place them in a shared style
sheet. This will ensure the contents are only included once in your application
binary.

```dart
@Component(
  selector: 'select-input',
  templateUrl: 'select_input_component.dart',
  styleUrls: const [
    'select_input_component.css',
    'input_common.css',
  ],
)
class SelectInputComponent {}

@Component(
  selector: 'text-input',
  templateUrl: 'text_input_component.dart',
  styleUrls: const [
    'text_input_component.css',
    'input_common.css',
  ],
)
class TextInputComponent {}
```

### DO use host selectors to style host elements

Encapsulated component styles can't select their component's host element by tag
name, since the element isn't actually inside the component's view. Instead,
special host selectors exist for selecting the host element in various contexts.

__BAD__:

```css
card {
  display: block;
}

card.bordered {
  border: 1px solid #000;
}

.emphasized card {
  font-weight: bold;
}
```

__GOOD__:

```css
:host {
  display: block;
}

/* The host element has the .bordered class. */
:host(.bordered) {
  border: 1px solid #000;
}

/* The host element or an ancestor has the .emphasized class. */
:host-context(.emphasized) {
  font-weight: bold;
}
```

### AVOID excessive use of ::ng-deep

The `::ng-deep` selector provides an escape hatch to prevent encapsulating
following selectors. This allows you to write a style rule capable of selecting
content not present in the static HTML of your component's template.

There are three main purposes for using this selector.

1.  Styling projected content inside an `<ng-content>` tag.
2.  Styling dynamic content bound to the `innerHtml` property of an element.
3.  Styling content of child components inside your component's view.

This should be used carefully and sparingly, as excessive use could lead to
unintentional style conflicts between components.

Ideally, your components should be designed to require little to no external
styling. It can become especially challenging to update a component's styles or
even template if other components depend on styling it using `::ng-deep`.

### AVOID using ::ng-deep as the left-most selector

Any style rule with a left-most `::ng-deep` selector has no encapsulation and
will match globally. Prefer to keep a selector that matches something in your
component's view to the left-hand side of `::ng-deep`. This will prevent the
style from leaking out of your component's view, while still allowing it to
match anything below it.

__BAD__:

```css
/* Matches globally. */
::ng-deep .link {
  text-decoration: none;
}
```

__BETTER__:

```css
/* Contained to an element in the component view with the .has-links class. */
.has-links ::ng-deep .link {
  text-decoration: none;
}
```
