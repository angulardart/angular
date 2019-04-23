# Cheat Sheet

go/angular-dart/cheat-sheet

[TOC]

<!--*
# Document freshness: For more information, see go/fresh-source.
freshness: { owner: 'alorenzen' reviewed: '2019-04-23' }
*-->

## Bootstrapping

*   ```dart
    import 'package:my_app/app_component.template.dart' as ng;

    void main() {
      runApp(ng.AppComponentNgFactory);
    }
    ```

    Launch the app, using AppComponent as the root component.

*   ```dart
    import 'package:angular_router/angular_router.dart';
    import 'package:my_app/app_component.template.dart' as ng;

    import 'main.template.dart' as self;

    @GenerateInjector(
      routerProviders,
    )
    final InjectorFactory injector = self.injector$Injector;

    void main() {
      runApp(ng.AppComponentNgFactory, createInjector: injector);
    }
    ```

    Launch the app, using a compile-time generated root injector.

## Template syntax

*   ```html
    <input [value]="firstName">
    ```

    Binds property value to the result of expression `firstName`.

*   ```html
    <div [attr.role]="myAriaRole">
    ```

    Binds attribute `role` to the result of expression `myAriaRole`.

*   ```html
    <div [class.extra-sparkle]="isDelightful">
    ```

    Binds the presence of the CSS class `extra-sparkle` on the element to the
    truthiness of the expression `isDelightful`.

*   ```html
    <div [style.width.px]="mySize">
    ```

    Binds style property `width` to the result of expression `mySize` in pixels.
    Units are optional.

*   ```html
    <button (click)="readRainbow($event)">
    ```

    or

    ```html
    <button (click)="readRainbow">
    ```

    Calls method `readRainbow` when a `click` event is triggered on this button
    element (or its children) and passes in the event object.

*   ```html
    <div title="Hello {{ponyName}}">
    ```

    Binds a property to an interpolated string, for example, “Hello Seabiscuit”.

    Equivalent to: `<div [title]="'Hello' + ponyName">`

*   ```html
    <p>Hello {{ponyName}}</p>
    ```

    Binds text content to an interpolated string, for example, “Hello
    Seabiscuit”.

*   ```html
    <my-cmp [(title)]="name">
    ```

    Sets up two-way data binding.

    Equivalent to: `<my-cmp [title]="name" (titleChange)="name=$event">`

*   ```html
    <video #movieplayer>
    </video>
    <button (click)="movieplayer.play()">
    ```

    Creates a local variable movieplayer that provides access to the video
    element instance in data-binding and event-binding expressions in the
    current template.

*   ```html
    <p>
      Card No.: {{cardNumber | myCardNumberFormatter}}
    </p>
    ```

    Transforms the current value of expression `cardNumber` via the pipe called
    `myCardNumberFormatter`.
