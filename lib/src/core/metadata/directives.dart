import "package:angular2/src/core/change_detection.dart"
    show ChangeDetectionStrategy;
import "package:angular2/src/core/di/metadata.dart" show InjectableMetadata;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;

/// Directives allow you to attach behavior to elements in the DOM.
///
/// [DirectiveMetadata]s with an embedded view are called [ComponentMetadata]s.
///
/// A directive consists of a single directive annotation and a controller
/// class. When the directive's [selector] matches elements in the DOM, the
/// following steps occur:
///
/// 1. For each directive, the [ElementInjector] attempts to resolve the
/// directive's constructor arguments.
/// 2. Angular instantiates directives for each matched element using
/// [ElementInjector] in a depth-first order, as declared in the HTML.
///
/// ## Understanding How Injection Works
///
/// There are three stages of injection resolution.
///
/// * Pre-existing Injectors:
///
///     - The terminal [Injector] cannot resolve dependencies. It either throws
///       an error or, if the dependency was specified as [Optional],
///       returns null.
///     - The platform injector resolves browser singleton resources, such as:
///       cookies, title, location, and others.
///
/// * Component Injectors: Each component instance has its own [Injector], and
///   they follow the same parent-child hierarchy as the component instances
///   in the DOM.
/// * Element Injectors*: Each component instance has a Shadow DOM. Within
///   the Shadow DOM each element has an [ElementInjector] which follow the
///   same parent-child hierarchy as the DOM elements themselves.
///
/// When a template is instantiated, it also must instantiate the corresponding
/// directives in a depth-first order. The current [ElementInjector] resolves
/// the constructor dependencies for each directive.
///
/// Angular then resolves dependencies as follows, according to the order in
/// which they appear in the [ViewMetadata]:
///
/// 1. Dependencies on the current element
/// 2. Dependencies on element injectors and their parents until it encounters
///    a Shadow DOM boundary
/// 3. Dependencies on component injectors and their parents until it encounters
///    the root component
/// 4. Dependencies on pre-existing injectors
///
///
/// The `ElementInjector` can inject other directives, element-specific special
/// objects, or it can delegate to the parent injector.
///
/// To inject other directives, declare the constructor parameter as:
///
/// - `DirectiveType directive`: a directive on the current element only
/// - `@Host() DirectiveType directive`: any directive that matches the type
///   between the current element and the Shadow DOM root.
/// - `@Query(DirectiveType) QueryList<DirectiveType> query`: A live collection
///   of direct child directives.
/// - `@QueryDescendants(DirectiveType) QueryList<DirectiveType> query`: A live
///   collection of any child directives.
///
/// To inject element-specific special objects, declare the constructor
/// parameter as:
///
/// - `ElementRef element`, to obtain a reference to logical element in the
///   view.
/// - `ViewContainerRef viewContainer`, to control child template instantiation,
///   for [DirectiveMetadata] directives only
/// - `BindingPropagation bindingPropagation`, to control change detection in a
///   more granular way.
///
/// ### Example
///
/// The following example demonstrates how dependency injection resolves
/// constructor arguments in practice.
///
/// Assume this HTML template:
///
///     <div dependency="1">
///       <div dependency="2">
///         <div dependency="3" my-directive>
///           <div dependency="4">
///             <div dependency="5"></div>
///           </div>
///           <div dependency="6"></div>
///         </div>
///       </div>
///     </div>
///
/// With the following dependency decorator and [SomeService] injectable class.
///
///     @Injectable()
///     class SomeService { }
///
///     @Directive(
///       selector: 'dependency',
///       inputs: [
///         'id: dependency'
///       ]
///     )
///     class Dependency {
///       String id;
///     }
///
/// Let's step through the different ways in which [MyDirective] could be
/// declared...
///
/// ### No injection
///
/// Here the constructor is declared with no arguments, therefore nothing is
/// injected into [MyDirective].
///
///     @Directive(selector: 'my-directive')
///     class MyDirective {
///       MyDirective();
///     }
///
/// This directive would be instantiated with no dependencies.
///
/// ### Component-level injection
///
/// Directives can inject any injectable instance from the closest component
/// injector or any of its parents.
///
/// Here, the constructor declares a parameter, [someService], and injects the
/// [SomeService] type from the parent component's injector.
///
///     @Directive({ selector: '[my-directive]' })
///     class MyDirective {
///       constructor(someService: SomeService) {
///       }
///     }
///
/// This directive would be instantiated with a dependency on [SomeService].
///
///
/// ### Injecting a directive from the current element
///
/// Directives can inject other directives declared on the current element.
///
///     @Directive(selector: 'my-directive')
///     class MyDirective {
///       MyDirective(Dependency dependency) {
///         expect(dependency.id, 3);
///       }
///     }
///
/// This directive would be instantiated with [Dependency] declared at the same
/// element, in this case `[dependency]="3"`.
///
/// ### Injecting a directive from any ancestor elements
///
/// Directives can inject other directives declared on any ancestor element
/// (in the current Shadow DOM), i.e. on the current element, the parent
/// element, or its parents.
///
///     @Directive(selector: 'my-directive')
///     class MyDirective {
///       MyDirective(@Host() Dependency dependency) {
///         expect(dependency.id, 2);
///       }
///     }
///
/// `@Host` checks the current element, the parent, as well as its parents
/// recursively. If `dependency="2"` didn't exist on the direct parent, this
/// injection would have returned `dependency="1"`.
///
///
/// ### Injecting a live collection of direct child directives
///
///
/// A directive can also query for other child directives. Since parent
/// directives are instantiated before child directives, a directive can't
/// simply inject the list of child directives. Instead, the directive injects
/// a [QueryList], which updates its contents as children are added,
/// removed, or moved by a directive that uses a [ViewContainerRef] such as a
/// `ngFor`, an `ngIf`, or an `ngSwitch`.
///
///     @Directive(selector: 'my-directive')
///     class MyDirective {
///       MyDirective(@Query(Dependency) QueryList<Dependency> dependencies);
///     }
///
/// This directive would be instantiated with a [QueryList] which contains
/// [Dependency] 4 and [Dependency] 6. Here, [Dependency] 5 would not be
/// included, because it is not a direct child.
///
/// ### Injecting a live collection of descendant directives
///
/// By passing the descendant flag to `@Query` above, we can include the
/// children of the child elements.
///
///     @Directive({ selector: '[my-directive]' })
///     class MyDirective {
///       MyDirective(@Query(Dependency, {descendants: true})
///           QueryList<Dependency> dependencies);
/// }
///
/// This directive would be instantiated with a Query which would contain
/// [Dependency] 4, 5 and 6.
///
/// ### Optional injection
///
/// The normal behavior of directives is to return an error when a specified
/// dependency cannot be resolved. If you would like to inject null on
/// unresolved dependency instead, you can annotate that dependency with
/// `@Optional()`. This explicitly permits the author of a template to treat
/// some of the surrounding directives as optional.
///
///     @Directive(selector: 'my-directive')
///     class MyDirective {
///       MyDirective(@Optional() Dependency dependency);
///     }
///
/// This directive would be instantiated with a [Dependency] directive found on
/// the current element. If none can be/ found, the injector supplies null
/// instead of throwing an error.
///
/// ### Example
///
/// Here we use a decorator directive to simply define basic tool-tip behavior.
///
///     @Directive(
///       selector: 'tooltip',
///       inputs: [
///         'text: tooltip'
///       ],
///       host: {
///         '(mouseenter)': 'onMouseEnter()',
///         '(mouseleave)': 'onMouseLeave()'
///       }
///     )
///     class Tooltip{
///       String text;
///       Overlay overlay;
///       OverlayManager overlayManager;
///
///       Tooltip(this.overlayManager);
///
///       onMouseEnter() {
///         overlay = overlayManager.open(text, ...);
///       }
///
///       onMouseLeave() {
///         overlay.close();
///         overlay = null;
///       }
///     }
///
/// In our HTML template, we can then add this behavior to a <div> or any other
/// element with the `tooltip` selector, like so:
///
///     <div tooltip="some text here"></div>
///
/// Directives can also control the instantiation, destruction, and positioning
/// of inline template elements:
///
/// A directive uses a [ViewContainerRef] to instantiate, insert, move, and
/// destroy views at runtime.
/// The [ViewContainerRef] is created as a result of `<template>` element,
/// and represents a location in the current view where these actions are
/// performed.
///
/// Views are always created as children of the current [ViewMetadata], and as
/// siblings of the `<template>` element. Thus a directive in a child view
/// cannot inject the directive that created it.
///
/// Since directives that create views via ViewContainers are common in Angular,
/// and using the full `<template>` element syntax is wordy, Angular
/// also supports a shorthand notation: `<li *foo="bar">` and
/// `<li template="foo: bar">` are equivalent.
///
/// Thus,
///
///     <ul>
///       <li *foo="bar" title="text"></li>
///     </ul>
///
/// Expands in use to:
///
///     <ul>
///       <template [foo]="bar">
///         <li title="text"></li>
///       </template>
///     </ul>
///
/// Notice that although the shorthand places `*foo="bar"` within the `<li>`
/// element, the binding for the directive controller is correctly instantiated
/// on the `<template>` element rather than the `<li>` element.
///
/// ## Lifecycle hooks
///
/// When the directive class implements some [lifecycle-hooks](docs/guide/lifecycle-hooks.html)
/// the callbacks are called by the change detection at defined points in time
/// during the life of the directive.
///
/// ### Example
///
/// Let's suppose we want to implement the `unless` behavior, to conditionally
/// include a template.
///
/// Here is a simple directive that triggers on an `unless` selector:
///
///     @Directive(
///       selector: 'unless',
///       inputs: ['unless']
///     )
///     class Unless {
///       ViewContainerRef viewContainer;
///       TemplateRef templateRef;
///       bool prevCondition;
///
///       Unless(this.viewContainer, this.templateRef);
///
///       set unless(newCondition) {
///         if (newCondition && (prevCondition == null || !prevCondition)) {
///           prevCondition = true;
///           viewContainer.clear();
///         } else if (!newCondition && (prevCondition == null ||
///             prevCondition)) {
///           prevCondition = false;
///           viewContainer.create(templateRef);
///         }
///       }
///     }
///
/// We can then use this `unless` selector in a template:
///
///     <ul>
///       <li///unless="expr"></li>
///     </ul>
///
/// Once the directive instantiates the child view, the shorthand notation for
/// the template expands and the result is:
///
///     <ul>
///       <template [unless]="exp">
///         <li></li>
///       </template>
///       <li></li>
///     </ul>
///
/// Note also that although the `<li></li>` template still exists inside the
/// `<template></template>`, the instantiated view occurs on the second
/// `<li></li>` which is a sibling to the `<template>` element.
///
///
class DirectiveMetadata extends InjectableMetadata {
  /// The CSS selector that triggers the instantiation of a directive.
  ///
  /// Angular only allows directives to trigger on CSS selectors that do not
  /// cross element boundaries.
  ///
  /// [selector] may be declared as one of the following:
  ///
  /// - `element-name`: select by element name.
  /// - `.class`: select by class name.
  /// - `[attribute]`: select by attribute name.
  /// - `[attribute=value]` : select by attribute name and value.
  /// - `:not(sub_selector)`: select only if the element does not match the
  ///   `sub_selector`.
  /// - `selector1, selector2`: select if either `selector1` or `selector2`
  ///   matches.
  ///
  ///
  /// ### Example
  ///
  /// Suppose we have a directive with an `input[type=text]` selector.
  ///
  /// And the following HTML:
  ///
  ///     <form>
  ///       <input type="text">
  ///       <input type="radio">
  ///     <form>
  ///
  /// The directive would only be instantiated on the `<input type="text">`
  /// element.
  ///
  ///
  final String selector;

  /// Enumerates the set of data-bound input properties for a directive
  ///
  /// Angular automatically updates input properties during change detection.
  ///
  /// The [inputs] property defines a set of _directiveProperty_ to
  /// _bindingProperty_ configuration:
  ///
  /// - _directiveProperty_ specifies the component property where the value
  ///   is written.
  /// - _bindingProperty_ specifies the DOM property where the value is read
  ///   from.
  ///
  /// When _bindingProperty_ is not provided, it is assumed to be equal to
  /// _directiveProperty_.
  ///
  /// The following example creates a component with two data-bound properties.
  ///
  ///     @Component(
  ///       selector: 'bank-account',
  ///       inputs: ['bankName', 'id: account-id'],
  ///       template: '''
  ///         Bank Name: {{bankName}}
  ///         Account Id: {{id}}
  ///       '''
  ///     )
  ///     class BankAccount {
  ///       String bankName;
  ///       String id;
  ///
  ///       // this property is not bound, and won't be automatically updated by
  ///       // Angular
  ///       String normalizedBankName;
  ///     }
  ///
  ///     @Component(
  ///       selector: 'app',
  ///       template: '''
  ///         <bank-account bank-name="RBC" account-id="4747"></bank-account>
  ///       ''',
  ///       directives: [BankAccount]
  ///     )
  ///     class App {}
  ///
  ///     bootstrap(App);
  ///
  final List<String> inputs;

  /// Enumerates the set of event-bound output properties.
  ///
  /// When an output property emits an event, an event handler attached to
  /// that event the template is invoked.
  ///
  /// The [outputs] property defines a set of _directiveProperty_ to
  /// _bindingProperty_ configuration:
  ///
  /// - _directiveProperty_ specifies the component property that emits events.
  /// - _bindingProperty_ specifies the DOM property the event handler is
  /// attached to.
  ///
  ///     @Directive(
  ///       selector: 'interval-dir',
  ///       outputs: ['everySecond', 'five5Secs: everyFiveSeconds']
  ///     )
  ///     class IntervalDir {
  ///       everySecond = new EventEmitter();
  ///       five5Secs = new EventEmitter();
  ///
  ///       IntervalDir() {
  ///         setInterval(() => everySecond.emit("event"), 1000);
  ///         setInterval(() => five5Secs.emit("event"), 5000);
  ///       }
  ///     }
  ///
  ///     @Component(
  ///       selector: 'app',
  ///       template: '''
  ///         <interval-dir (everySecond)="everySecond()" (everyFiveSeconds)="everyFiveSeconds()">
  ///         </interval-dir>
  ///       ''',
  ///       directives: [IntervalDir]
  ///     )
  ///     class App {
  ///       everySecond() { print('second'); }
  ///       everyFiveSeconds() { print('five seconds'); }
  ///     }
  ///     bootstrap(App);
  ///

  final List<String> outputs;

  /// Specify the events, actions, properties and attributes related to the host
  /// element.
  ///
  /// ## Host Listeners
  ///
  /// Specifies which DOM events a directive listens to via a set of '(_event_)'
  /// to _statement_ key-value pairs:
  ///
  /// - _event_: the DOM event that the directive listens to.
  /// - _statement_: the statement to execute when the event occurs.
  /// If the evaluation of the statement returns [false], then [preventDefault]
  /// is applied on the DOM event.
  ///
  /// To listen to global events, a target must be added to the event name.
  /// The target can be `window`, `document` or `body`.
  ///
  /// When writing a directive event binding, you can also refer to the $event
  /// local variable.
  ///
  ///
  /// The following example declares a directive that attaches a click listener
  /// to the button and counts clicks.
  ///
  ///     @Directive(
  ///       selector: 'button[counting]',
  ///       host: {
  ///         '(click)': 'onClick($event.target)'
  ///       }
  ///     })
  ///     class CountClicks {
  ///       var numberOfClicks = 0;
  ///
  ///       onClick(btn) {
  ///         print("button $btn, number of clicks: ${numberOfClicks++}");
  ///       }
  ///     }
  ///
  ///     @Component(
  ///       selector: 'app',
  ///       template: `<button counting>Increment</button>`,
  ///       directives: [CountClicks]
  ///     )
  ///     class App {}
  ///
  ///     bootstrap(App);
  ///
  /// ## Host Property Bindings
  ///
  /// Specifies which DOM properties a directive updates.
  ///
  /// Angular automatically checks host property bindings during change
  /// detection. If a binding changes, it will update the host element of the
  /// directive.
  ///
  /// The following example creates a directive that sets the `valid` and
  /// `invalid` classes on the DOM element that has ngModel directive on it.
  ///
  ///     @Directive(
  ///       selector: '[ngModel]',
  ///       host: {
  ///         '[class.valid]': 'valid',
  ///         '[class.invalid]': 'invalid'
  ///       }
  ///     )
  ///     class NgModelStatus {
  ///       NgModel control;
  ///
  ///       NgModelStatus(this.control);
  ///       get valid => control.valid;
  ///       get invalid => control.invalid;
  ///     }
  ///
  ///     @Component({
  ///       selector: 'app',
  ///       template: `<input [(ngModel)]="prop">`,
  ///       directives: [FORM_DIRECTIVES, NgModelStatus]
  ///     })
  ///     class App {
  ///       prop;
  ///     }
  ///
  ///     bootstrap(App);
  ///
  /// ## Attributes
  ///
  /// Specifies static attributes that should be propagated to a host element.
  ///
  /// ### Example
  ///
  /// In this example using `my-button` directive (ex.: `<div my-button></div>`)
  /// on a host element (here: `<div>` ) will ensure that this element will get
  /// the "button" role.
  ///
  ///     @Directive(
  ///       selector: '[my-button]',
  ///       host: {
  ///         'role': 'button'
  ///       }
  ///     )
  ///     class MyButton {
  ///     }
  ///
  final Map<String, String> host;

  /// Defines the set of injectable objects that are visible to a Directive and
  /// its light DOM children.
  ///
  /// ## Simple Example
  ///
  /// Here is an example of a class that can be injected:
  ///
  ///     class Greeter {
  ///        void greet(String name) => 'Hello ${name}!';
  ///     }
  ///
  ///     @Directive(
  ///       selector: 'greet',
  ///       bindings: [
  ///         Greeter
  ///       ]
  ///     )
  ///     class HelloWorld {
  ///       Greeter greeter;
  ///
  ///       HelloWorld(this.greeter);
  ///     }
  ///
  final List providers;

  /// Defines the name that can be used in the template to assign this directive
  /// to a variable.
  ///
  /// ## Simple Example
  ///
  ///     @Directive(
  ///       selector: 'child-dir',
  ///       exportAs: 'child'
  ///     )
  ///     class ChildDir {
  ///     }
  ///
  ///     @Component(
  ///       selector: 'main',
  ///       template: `<child-dir #c="child"></child-dir>`,
  ///       directives: [ChildDir]
  ///     )
  ///     class MainComponent {
  ///     }
  ///
  final String exportAs;

// TODO: add an example after ContentChildren and ViewChildren are in master

  /// Configures the queries that will be injected into the directive.
  ///
  /// Content queries are set before the [ngAfterContentInit] callback is
  /// called. View queries are set before the [ngAfterViewInit] callback is
  /// called.
  ///
  /// ### Example
  ///
  ///     @Component(
  ///       selector: 'someDir',
  ///       queries: {
  ///         contentChildren: new ContentChildren(ChildDirective),
  ///         viewChildren: new ViewChildren(ChildDirective)
  ///       },
  ///       template: '<child-directive></child-directive>',
  ///       directives: [ChildDirective]
  ///     )
  ///     class SomeDir {
  ///       QueryList<ChildDirective> contentChildren;
  ///       QueryList<ChildDirective> viewChildren;
  ///
  ///       ngAfterContentInit() {
  ///         // contentChildren is set
  ///       }
  ///
  ///       ngAfterViewInit() {
  ///         // viewChildren is set
  ///       }
  ///     }
  ///
  final Map<String, dynamic> queries;

  const DirectiveMetadata(
      {String selector,
      this.inputs,
      this.outputs,
      Map<String, String> host,
      this.providers,
      String exportAs,
      Map<String, dynamic> queries})
      : selector = selector,
        host = host,
        exportAs = exportAs,
        queries = queries,
        super();
}

/// Declare reusable UI building blocks for an application.
///
/// Each Angular component requires a single `@Component` annotation. The
/// `@Component` annotation specifies when a component is instantiated, and
/// which properties and hostListeners it binds to.
///
/// When a component is instantiated, Angular
///
/// - creates a shadow DOM for the component.
/// - loads the selected template into the shadow DOM.
/// - creates all the injectable objects configured with [providers] and
///   [viewProviders].
///
/// All template expressions and statements are then evaluated against the
/// component instance.
///
/// For details on the `@View` annotation, see [ViewMetadata].
///
/// ## Lifecycle hooks
///
/// When the component class implements some [lifecycle-hooks](docs/guide/lifecycle-hooks.html)
/// the callbacks are called by the change detection at defined points in time
/// during the life of the component.
///
class ComponentMetadata extends DirectiveMetadata {
  /// Defines the used change detection strategy.
  ///
  /// When a component is instantiated, Angular creates a change detector, which
  /// is responsible for propagating the component's bindings.
  ///
  /// The [changeDetection] property defines, whether the change detection will
  /// be checked every time or only when the component tells it to do so.
  ///
  final ChangeDetectionStrategy changeDetection;

  /// Defines the set of injectable objects that are visible to its view DOM children.
  ///
  /// ## Simple Example
  ///
  /// Here is an example of a class that can be injected:
  ///
  ///     class Greeter {
  ///        greet(String name) => 'Hello ${name}!';
  ///     }
  ///
  ///     @Directive(
  ///       selector: 'needs-greeter'
  ///     )
  ///     class NeedsGreeter {
  ///       final Greeter greeter;
  ///
  ///       NeedsGreeter(this.greeter);
  ///     }
  ///
  ///     @Component(
  ///       selector: 'greet',
  ///       viewProviders: [
  ///         Greeter
  ///       ],
  ///       template: '<needs-greeter></needs-greeter>',
  ///       directives: [NeedsGreeter]
  ///     )
  ///     class HelloWorld {
  ///     }
  ///
  List get viewProviders => (_viewBindings != null && _viewBindings.isNotEmpty)
      ? this._viewBindings
      : this._viewProviders;

  List get viewBindings {
    return this.viewProviders;
  }

  final List _viewProviders;
  final List _viewBindings;

  /// The module id of the module that contains the component.
  /// Needed to be able to resolve relative urls for templates and styles.
  /// In Dart, this can be determined automatically and does not need to be set.
  /// In CommonJS, this can always be set to `module.id`.
  ///
  /// ## Simple Example
  ///
  ///     @Directive(
  ///       selector: 'someDir',
  ///       moduleId: module.id
  ///     })
  ///     class SomeDir {
  ///     }
  ///
  final String moduleId;
  final String templateUrl;
  final String template;
  final bool preserveWhitespace;
  final List<String> styleUrls;
  final List<String> styles;
  final List<dynamic /* Type | List < dynamic > */ > directives;
  final List<dynamic /* Type | List < dynamic > */ > pipes;
  final ViewEncapsulation encapsulation;
  const ComponentMetadata(
      {String selector,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      String exportAs,
      this.moduleId,
      List providers,
      List viewBindings,
      List viewProviders,
      this.changeDetection: ChangeDetectionStrategy.Default,
      Map<String, dynamic> queries,
      this.templateUrl,
      this.template,
      this.preserveWhitespace: false,
      this.styleUrls,
      this.styles,
      this.directives,
      this.pipes,
      this.encapsulation})
      : _viewProviders = viewProviders,
        _viewBindings = viewBindings,
        super(
            selector: selector,
            inputs: inputs,
            outputs: outputs,
            host: host,
            exportAs: exportAs,
            providers: providers,
            queries: queries);
}

/// Declare reusable pipe function.
///
/// A "pure" pipe is only re-evaluated when either the input or any of the
/// arguments change. When not specified, pipes default to being pure.
///
class PipeMetadata extends InjectableMetadata {
  final String name;
  final bool _pure;
  const PipeMetadata({this.name, bool pure})
      : _pure = pure,
        super();
  bool get pure => _pure ?? true;
}

/// Declares a data-bound input property.
///
/// Angular automatically updates data-bound properties during change detection.
///
/// [InputMetadata] takes an optional parameter that specifies the name
/// used when instantiating a component in the template. When not provided,
/// the name of the decorated property is used.
///
/// ### Example
///
/// The following example creates a component with two input properties.
///
///     @Component(
///       selector: 'bank-account',
///       template: '''
///         Bank Name: {{bankName}}
///         Account Id: {{id}}
///       '''
///     )
///     class BankAccount {
///       @Input()
///       String bankName;
///       @Input('account-id')
///       String id;
///
///       // this property is not bound, and won't be automatically updated
///       String normalizedBankName;
///     }
///
///     @Component(
///       selector: 'app',
///       template: '''
///         <bank-account bank-name="RBC" account-id="4747"></bank-account>
///       ''',
///       directives: [BankAccount]
///     })
///     class App {}
///
///     bootstrap(App);
///
class InputMetadata {
  final String bindingPropertyName;
  const InputMetadata(
      [

      /// Name used when instantiating a component in the template.
      this.bindingPropertyName]);
}

/// Declares an event-bound output property.
///
/// When an output property emits an event, an event handler attached to that
/// event the template is invoked.
///
/// [OutputMetadata] takes an optional parameter that specifies the name
/// used when instantiating a component in the template. When not provided,
/// the name of the decorated property is used.
///
/// ### Example
///
///     @Directive(
///       selector: 'interval-dir',
///     )
///     class IntervalDir {
///       @Output()
///       var everySecond = new EventEmitter();
///
///       @Output('everyFiveSeconds')
///       var five5Secs = new EventEmitter();
///
///       IntervalDir() {
///         setInterval(() => everySecond.emit("event"), 1000);
///         setInterval(() => five5Secs.emit("event"), 5000);
///       }
///     }
///
///     @Component(
///       selector: 'app',
///       template: '''
///         <interval-dir (everySecond)="everySecond()"
///                       (everyFiveSeconds)="everyFiveSeconds()">
///         </interval-dir>
///       ''',
///       directives: [IntervalDir]
///     )
///     class App {
///       everySecond() { print('second'); }
///       everyFiveSeconds() { print('five seconds'); }
///     }
///     bootstrap(App);
///
class OutputMetadata {
  final String bindingPropertyName;
  const OutputMetadata([this.bindingPropertyName]);
}

/// Declares a host property binding.
///
/// Angular automatically checks host property bindings during change detection.
/// If a binding changes, it will update the host element of the directive.
///
/// [HostBindingMetadata] takes an optional parameter that specifies the
/// property name of the host element that will be updated. When not provided,
/// the class property name is used.
///
/// ### Example
///
/// The following example creates a directive that sets the `valid` and
/// `invalid` classes on the DOM element that has ngModel directive on it.
///
///     @Directive({selector: '[ngModel]'})
///     class NgModelStatus {
///       NgModel control;
///       NgModelStatus(this.control);
///           @HostBinding('class.valid')
///           bool get valid => return control.valid;
///       @HostBinding('class.invalid')
///       bool get invalid => control.invalid;
///     }
///
///     @Component(
///       selector: 'app',
///       template: `<input [(ngModel)]="prop">`,
///       directives: [FORM_DIRECTIVES, NgModelStatus]
///     )
///     class App {
///       var prop;
///     }
///
///     bootstrap(App);
///
class HostBindingMetadata {
  final String hostPropertyName;
  const HostBindingMetadata([this.hostPropertyName]);
}

/// Declares a host listener.
///
/// Angular will invoke the decorated method when the host element emits the
/// specified event.
///
/// If the decorated method returns [false], then [preventDefault] is applied
/// on the DOM event.
///
/// ### Example
///
/// The following example declares a directive that attaches a click listener to
/// the button and counts clicks.
///
///     @Directive(selector: 'button[counting]')
///     class CountClicks {
///       int numberOfClicks = 0;
///
///       @HostListener('click', ['$event.target'])
///       onClick(btn) {
///         print("button $btn, number of clicks: ${numberOfClicks++});
///       }
///     }
///
///     @Component(
///       selector: 'app',
///       template: `<button counting>Increment</button>`,
///       directives: [CountClicks]
///     )
///     class App {}
///
///     bootstrap(App);
///
class HostListenerMetadata {
  final String eventName;
  final List<String> args;
  const HostListenerMetadata(this.eventName, [this.args]);
}
