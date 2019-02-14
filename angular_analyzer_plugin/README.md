** WARNING: ** You are looking at a copy of [https://github.com/dart-lang/angular_analyzer_plugin].
We are in the process of moving that repo into the angular repo. This is still
ongoing and so the code here is not complete.

[![Build Status](https://travis-ci.org/dart-lang/angular_analyzer_plugin.svg?branch=master)](https://travis-ci.org/dart-lang/angular_analyzer_plugin) [![pub package](https://img.shields.io/pub/v/angular_analyzer_plugin.svg)](https://pub.dartlang.org/packages/angular_analyzer_plugin)

**Requires angular-5.0.0\* and dart SDK 2.0.0-dev.31\*\* or higher to work.**

\* Works with angular-4.0.0 by following the steps in the section "loading an exact version."

\*\* Linux and Mac users should be able to an SDK version as old as 1.25.0-dev.12.0

## Integration with Dart Analysis Server

  To provide information for DAS clients the `server_plugin` plugin contributes several extensions.

* Angular analysis errors are automatically merged into normal `errors` notifications for Dart and HTML files.

![Preview gif](https://raw.githubusercontent.com/dart-lang/angular_analyzer_plugin/master/assets/angular-dart-intellij-plugin-demo.gif "Preview gif")

## Installing By Angular Version -- For Angular Developers (recommended)

Using this strategy allows the dart ecosystem to discover which version of our plugin will work best with your version of angular, and therefore is recommended.

Simply add to your [analysis_options.yaml file](https://www.dartlang.org/guides/language/analysis-options#the-analysis-options-file):

```yaml
analyzer:
  plugins:
    - angular
```

Then simply reboot your analysis server (inside IntelliJ this is done by clicking on the skull icon if it exists, or the refresh icon otherwise) and wait for the plugin to fully load, which can take a minute on the first run.

The plugin will self-upgrade if you update angular. Otherwise, you can get any version of the plugin you wish by following the steps in the next section.

## Loading an Exact Version

This is much like the previous step. However, you should include this project in your pubspec:

```yaml
dependencies:
  angular_analyzer_plugin: 0.0.13
```

and then load the plugin as itself, rather than as a dependency of angular:

```yaml
analyzer:
  plugins:
    - angular_analyzer_plugin
```

Like the previous installation option, you then just need to reboot your analysis server after running pub get.

## Troubleshooting

If you have any issues, filing an issue with us is always a welcome option. There are a few things you can try on your own, as well, to get an idea of what's going wrong:

* Are you using angular 5 or newer? If not, are you loading a recent exact version of the plugin?
* Are you using a bleeding edge SDK? The latest stable will not work correctly, and windows users require at least 2.0.0-dev-31.
* Did you turn the plugin on correctly in your analysis options file?
* From IntelliJ in the Dart Analysis panel, there's a gear icon that has "analyzer diagnostics," which opens a web page that has a section for loaded plugins. Are there any errors?
* Does your editor support html+dart analysis, or is it an old version? Some (such as VSCode, vim) may have special steps to show errors surfaced by dart analysis inside your html files.
* Check the directory `~/.dartServer/.plugin_manager` (on Windows: `\Users\you\AppData\Local\.dartServer\.plugin_manager`). Does it have any subdirectories?
* There should be a hash representing each plugin you've loaded. Can you run `pub get` from `HASH/analyzer_plugin`? (If you have multiple hashes, it should be safe to clear this directory & reload.)
* If you run `bin/plugin.dart` from `.plugin_manager/HASH/analyzer_plugin`, do you get any import errors? (Note: this is expected to crash when launched in this way, but without import-related errors)

We may ask you any or all of these questions if you open an issue, so feel free to go run through these checks on your own to get a hint what might be wrong.

## Upgrading

Any Dart users on 2.0.0-dev.48 or newer will get updates on every restart of the analysis server. If you are on an older Dart version than that, check the Troubleshooting section.

## Building -- For hacking on this plugin, or using the latest unpublished.

There's an `pubspec.yaml` file that needs to be updated to point to your local system:

```console
$ cd angular_analyzer_plugin/tools/analyzer_plugin
$ cp pubspec.yaml.defaults pubspec.yaml
```

Modify `pubspec.yaml` in this folder to fix the absolute paths. They **must** be absolute!

Then run `pub get`.

You can now use this in projects on your local system which a correctly configured pubspec and analysis options. For instance, `playground/`. Note that it imports the plugin by path, and imports it as a plugin inside `analysis_options.yaml`.

## Chart of Current Features

We plug into many editors with varying degrees of support. In theory anything that supports Dart analysis also supports our plugin, but in practice that's not always the case.

Bootstrapping | Validation | Auto-Complete | Navigation | Refactoring
--------------|------------|---------------|------------|-------------
IntelliJ | :white_check_mark: | :white_check_mark: | :warning: some support in EAP | :no_pedestrians:
Vim (special setup required) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :no_pedestrians:
VS Code (Dart Code [w/ flag](https://github.com/Dart-Code/Dart-Code/issues/396)) | :white_check_mark: | :question: | :question: | :no_pedestrians:
others | :question: let us know! | :question: let us know! | :question: let us know! | :question: let us know!

If you are using an editor with Dart support that's not in this list, then please let us know what does or doesn't work. We can sometimes contribute fixes, too!

Bootstrapping | Validation | Auto-Complete | Navigation | Refactoring
--------------|------------|---------------|------------|-------------
`bootstrap(AppComponent, [MyService, provide(...)]);` | :no_pedestrians: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:

Template syntax | Validation | Auto-Complete | Navigation | Refactoring
----------------|------------|---------------|------------|-------------
`<div stringInput="string">` | :white_check_mark: typecheck is string input on component | :white_check_mark: | :white_check_mark: | :x:
`<input [value]="firstName">` | :white_check_mark: soundness of expression, type of expression, existence of `value` on element or directive | :white_check_mark: | :white_check_mark: | :x:
`<input bind-value="firstName">` | :white_check_mark: | :skull: | :white_check_mark: | :x:
`<div [attr.role]="myAriaRole">` | :last_quarter_moon: soundness of expression, but no other validation | :last_quarter_moon: complete inside binding but binding not suggested | :last_quarter_moon: no html specific navigation | :x:
`<div [attr.role.if]="myAriaRole">` | :white_check_mark: | :last_quarter_moon: complete inside binding but binding not suggested | :white_check_mark: | :x:
`<div [class.extra-sparkle]="isDelightful">` | :white_check_mark: validity of clasname, soundness of expression, type of expression must be bool | :last_quarter_moon: complete inside binding but binding not suggested | :last_quarter_moon: no css specific navigation | :x:
`<div [style.width.px]="mySize">` | :waning_gibbous_moon: soundness of expression, css properties are generally checked but not against a dictionary, same for units, expression must type to `int` if units are present | :last_quarter_moon: complete inside binding but binding not suggested | :last_quarter_moon: no css specific navigation | :x:
`<button (click)="readRainbow($event)">` | :white_check_mark: soundness of expression, type of `$event`, existence of output on component/element and DOM events which propagate can be tracked anywhere | :white_check_mark: | :last_quarter_moon: no navigation for `$event` | :x:
`<button (keyup.enter)="...">` | :waning_gibbous_moon: soundness of expression, type of `$event`, keycode and modifier names not checked | :white_check_mark: | :last_quarter_moon: no navigation for `$event` | :x:
`<button on-click="readRainbow($event)">` | :white_check_mark: | :skull: | :last_quarter_moon: no navigation for `$event` | :x:
`<div title="Hello {{ponyName}}">` | :white_check_mark: soundness of expression, matching mustache delimiters | :white_check_mark: | :white_check_mark: | :x:
`<p>Hello {{ponyName}}</p>` | :white_check_mark: soundness of expression, matching mustache delimiters | :white_check_mark: | :white_check_mark: | :x:
`<my-cmp></my-cmp>` | :white_check_mark: existence of directive |:white_check_mark: | :white_check_mark: | :x:
`<my-cmp [(title)]="name">` | :white_check_mark: soundness of expression, existence of `title` input and `titleChange` output on directive or component with proper type | :white_check_mark: | :white_check_mark: navigates to the input | :x:
`<video #movieplayer ...></video><button (click)="movieplayer.play()">` | :white_check_mark: type of new variable tracked and checked in other expressions | :white_check_mark: | :white_check_mark: | :x:
`<video directiveWithExportAs #moviePlayer="exportAsValue">` | :white_check_mark: existence of exportAs value checked within bound directives | :white_check_mark: | :white_check_mark: | :x:
`<video ref-movieplayer ...></video><button (click)="movieplayer.play()">` | :white_check_mark: |:white_check_mark: | :white_check_mark: | :x:
`<p *myUnless="myExpression">...</p>` | :white_check_mark: desugared to `<template [myUnless]="myExpression"><p>...` and checked from there | :white_check_mark: | :white_check_mark: some bugs ,mostly works | :x:
`<p>Card No.: {{cardNumber \| myCardNumberFormatter}}</p>` | :first_quarter_moon: Pipe name, input, and return type checked, optional argument types not yet checked| :x: | :x: | :x:
`<my-component @deferred>` | :x: | :x: | :x: | :x:

Built-in directives | Validation | Auto-Complete | Navigation | Refactoring
--------------------|------------|---------------|------------|-------------
`<section *ngIf="showSection">` | :white_check_mark: type checking, check for the star | :white_check_mark: | :white_check_mark: | :x:
`<li *ngFor="let item of list">` | :white_check_mark: type checking and new var, check for the star, catch accidental usage of `#item` | :white_check_mark: | :last_quarter_moon: some bugs, mostly works | :x:
`<div [ngClass]="{active: isActive, disabled: isDisabled}">` | :warning: Requires quotes around key value strings to work | :white_check_mark: | :white_check_mark: | :x:

Forms | Validation | Auto-Complete | Navigation | Refactoring
------|------------|---------------|------------|-------------
`<input [(ngModel)]="userName">` | :white_check_mark: | :white_check_mark: | :white_check_mark: goes to `ngModel` input | :x:
`<form #myform="ngForm">` | :white_check_mark: if `ngForm` is not an exported directive | :white_check_mark: | :white_check_mark: | :x:

Class decorators | Validation | Auto-Complete | Navigation | Refactoring
-----------------|------------|---------------|------------|-------------
`@Component(...) class MyComponent {}` | :white_check_mark: Validates directives list is all directives, that the template file exists, that a template is specified via string or URL but not both, requires a valid selector | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`@View(...) class MyComponent {}` | :warning: Supported, requires `@Directive` or `@Component`, but doesn't catch ambigous cases such as templates defined in the `@View` as well as `@Component` | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`@Directive(...) class MyDirective {}` | :white_check_mark: Validates directives list is all directives, requires a valid selector | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`@Directive(...) void directive(...) {}` | :white_check_mark: Validates directives list is all directives requires a valid selector, not exported | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`@Pipe(...) class MyPipe {}` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`@Injectable() class MyService {}` | :x: | :no_pedestrians: | :no_pedestrians: | :x:

Directive configuration | Validation | Auto-Complete | Navigation | Refactoring
------------------------|------------|---------------|------------|-------------
`@Directive(property1: value1, ...)` | :warning: deprecated, but supported | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`selector: '.cool-button:not(a)'` | :white_check_mark: | :no_pedestrians: | :white_check_mark: selectors can be reached from matching html | :x:
`providers: [MyService, provide(...)]` | :x: | :x: | :x: | :x:
`inputs: ['myprop', 'myprop2: byname']` | :white_check_mark: | :x: | :white_check_mark: | :x:
`outputs: ['myprop', 'myprop2: byname']` | :white_check_mark: | :x: | :white_check_mark: | :x:

@Component extends @Directive, so the @Directive configuration applies to components as well

Component Configuration | Validation | Auto-Complete | Navigation | Refactoring
------------------------|------------|---------------|------------|-------------
`viewProviders: [MyService, provide(...)]` | :x: | :x: | :x: | :x:
`template: 'Hello {{name}}'` | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:
`templateUrl: 'my-component.html'` | :white_check_mark: | :x: | :white_check_mark: | :x:
`styles: ['.primary {color: red}']` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`styleUrls: ['my-component.css']` | :x: | :x: | :x: | :x:
`directives: [MyDirective, MyComponent]` | :white_check_mark: must be directives or lists of directives, configuration affects view errors | :x: | :white_check_mark: regular navigation | :x:
`pipes: [MyPipe, OtherPipe]` | :x: | :x: | :white_check_mark: regular navigation | :x:
`exports: [Class, Enum, staticFn]` | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:

Class field decorators for directives and components | Validation | Auto-Complete | Navigation | Refactoring
-----------------------------------------------------|------------|---------------|------------|-------------
`@Input() myProperty;` | :white_check_mark: | :no_pedestrians: | :x: | :x:
`@Input("name") myProperty;` | :white_check_mark: | :no_pedestrians: | :x: | :x:
`@Output() myEvent = new Stream<X>();` | :white_check_mark: Subtype of `Stream<T>` required, streamed type determines `$event` type | :no_pedestrians: | :x: | :x:
`@Output("name") myEvent = new Stream<X>();` | :white_check_mark: | :no_pedestrians: | :x: | :x:
`@Attribute("name") String ctorArg` | :white_check_mark: | :x: | :x: | :x:
`@HostBinding('[class.valid]') isValid;` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`@HostListener('click', ['$event']) onClick(e) {...}` | :x: | :x: | :x: | :x:
`@ContentChild(myPredicate) myChildComponent;` | :x: | :no_pedestrians: | :x: | :x:
`@ContentChildren(myPredicate) myChildComponents;` | :x: | :no_pedestrians: | :x: | :x:
`@ViewChild(myPredicate) myChildComponent;` | :x: | :no_pedestrians: | :x: | :x:
`@ViewChildren(myPredicate) myChildComponents;` | :x: | :no_pedestrians: | :x: | :x:

Transclusions| Validation | Auto-Complete | Navigation | Refactoring
-----------------------------------------------------|------------|---------------|------------|-------------
`<ng-content></ng-content>` | :white_check_mark: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`<my-comp>text content</my-comp>` | :white_check_mark: | :x: | :x: | :x:
`<ng-content select="foo"></ng-content>` | :white_check_mark: | :white_check_mark: | :white_check_mark: navigation from where matched | :x:
`<my-comp><foo></foo></my-comp>` | :white_check_mark: | :white_check_mark: | :white_check_mark: navigation to the corresponding selector | :x:
`<ng-content select=".foo[bar]"></ng-content>` | :white_check_mark: | :white_check_mark: | :white_check_mark: navigation from where matched | :x:
`<my-comp><div class="foo" bar></div></my-comp>` | :white_check_mark: | :white_check_mark: | :white_check_mark: navigation to the corresponding selector | :x:

Directive and component change detection and lifecycle hooks (implemented as class methods) | Validation | Auto-Complete | Navigation | Refactoring
--------------------------------------------------------------------------------------------|------------|---------------|------------|-------------
`MyAppComponent(MyService myService, ...) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngOnChanges(changeRecord) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngOnInit() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngDoCheck() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngAfterContentInit() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngAfterContentChecked() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngAfterViewInit() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`ngAfterViewChecked() { ... }` | :no_pedestrians: | :no_pedestrians: | :x: | :x:
`ngOnDestroy() { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :x:

Dependency injection configuration | Validation | Auto-Complete | Navigation | Refactoring
-----------------------------------|------------|---------------|------------|-------------
`provide(MyService, useClass: MyMockService)` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`provide(MyService, useFactory: myFactory)` | :x: | :no_pedestrians: | :no_pedestrians: | :x:
`provide(MyValue, useValue: 41)` | :x: | :no_pedestrians: | :no_pedestrians: | :x:

Routing and navigation | Validation | Auto-Complete | Navigation | Refactoring
-----------------------|------------|---------------|------------|-------------
`@RouteConfig(const [ const Route(...) ])` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`<router-outlet></router-outlet>` | :no_pedestrians: | :x: | :no_pedestrians: | :no_pedestrians:
`<a [routerLink]="[ '/MyCmp', {myParam: 'value' } ]">` | :question: | :x: | :no_pedestrians: | :no_pedestrians:
`@CanActivate(() => ...)class MyComponent() {}` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`routerOnActivate(nextInstruction, prevInstruction) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`routerCanReuse(nextInstruction, prevInstruction) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`routerOnReuse(nextInstruction, prevInstruction) { ... }` | :x: | :x: | :no_pedestrians: | :no_pedestrians:
`routerCanDeactivate(nextInstruction, prevInstruction) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
`routerOnDeactivate(nextInstruction, prevInstruction) { ... }` | :x: | :no_pedestrians: | :no_pedestrians: | :no_pedestrians:
