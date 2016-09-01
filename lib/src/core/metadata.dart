import 'package:angular2/src/core/change_detection/change_detection.dart';

import 'metadata/di.dart';
import 'metadata/view.dart';

export './metadata/view.dart' hide VIEW_ENCAPSULATION_VALUES;
export 'metadata/di.dart';
export 'metadata/lifecycle_hooks.dart'
    show
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked,
        OnChanges,
        OnDestroy,
        OnInit,
        DoCheck;

/// Directives allow you to attach behavior to elements in the DOM.
///
/// [Directive]s with an embedded view are called [Component]s.
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
/// which they appear in the [View]:
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
///   for [Directive] directives only
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
/// Views are always created as children of the current [ViewMeta], and as
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
class Directive extends Injectable {
  /// The CSS selector that triggers the instantiation of a directive.
  ///
  /// Angular only allows directives to trigger on CSS selectors that do not
  /// cross element boundaries.
  ///
  /// The [selector] may be declared as one of the following:
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
  /// ### Example
  ///
  /// Suppose we have a directive with an `input[type=text]` selector.
  ///
  /// And the following HTML:
  ///
  /// ```html
  /// <form>
  ///   <input type="text">
  ///   <input type="radio">
  /// <form>
  /// ```
  ///
  /// The directive would only be instantiated on the `<input type="text">`
  /// element.
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
  /// ```dart
  /// @Component(
  ///   selector: 'bank-account',
  ///   inputs: const ['bankName', 'id: account-id'],
  ///   template: '''
  ///     Bank Name: {{bankName}}
  ///     Account Id: {{id}}
  ///   ''')
  /// class BankAccount {
  ///   String bankName, id;
  ///
  ///   // This property is not bound, and won't be automatically updated by
  ///   // Angular
  ///   String normalizedBankName;
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: '''
  ///     <bank-account bank-name="RBC" account-id="4747"></bank-account>
  ///   ''',
  ///   directives: const [BankAccount])
  /// class App {}
  /// ```
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
  /// ```dart
  /// @Directive(
  ///   selector: 'interval-dir',
  ///   outputs: const ['everySecond', 'five5Secs: everyFiveSeconds'])
  /// class IntervalDir {
  ///   final everySecond = new EventEmitter<String>();
  ///
  ///   final five5Secs = new EventEmitter<String>();
  ///
  ///   IntervalDir() {
  ///     setInterval(() => everySecond.emit("event"), 1000);
  ///     setInterval(() => five5Secs.emit("event"), 5000);
  ///   }
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: '''
  ///     <interval-dir (everySecond)="everySecond()" (everyFiveSeconds)="everyFiveSeconds()">
  ///     </interval-dir>
  ///   ''',
  ///   directives: const [IntervalDir])
  /// class App {
  ///   everySecond() { print('second'); }
  ///   everyFiveSeconds() { print('five seconds'); }
  /// }
  /// ```
  final List<String> outputs;

  /// Specify the events, actions, properties and attributes related to the host
  /// element.
  ///
  /// ## Host Listeners
  /// Specifies which DOM events a directive listens to via a set of '(_event_)'
  /// to _statement_ key-value pairs:
  ///
  /// - _event_: the DOM event that the directive listens to
  /// - _statement_: the statement to execute when the event occurs
  ///
  /// If the evaluation of the statement returns [false], then [preventDefault]
  /// is applied on the DOM event.
  ///
  /// To listen to global events, a target must be added to the event name.
  /// The target can be `window`, `document` or `body`.
  ///
  /// When writing a directive event binding, you can also refer to the $event
  /// local variable.
  ///
  /// The following example declares a directive that attaches a click listener
  /// to the button and counts clicks.
  ///
  /// ```dart
  /// @Directive(
  ///   selector: 'button[counting]',
  ///   host: const {
  ///     '(click)': 'onClick($event.target)'
  ///   })
  /// class CountClicks {
  ///   var numberOfClicks = 0;
  ///
  ///   void onClick(btn) {
  ///     print("Button $btn, number of clicks: ${numberOfClicks++}.");
  ///   }
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: `<button counting>Increment</button>`,
  ///   directives: const [CountClicks])
  /// class App {}
  /// ```
  ///
  /// ## Host Property Bindings
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
  /// ```dart
  /// @Directive(
  ///   selector: '[my-button]',
  ///   host: const {
  ///     'role': 'button'
  ///   })
  /// class MyButton {}
  /// ```
  final Map<String, String> host;

  /// Defines the set of injectable objects that are visible to a Directive and
  /// its light DOM children.
  ///
  /// ### Example
  /// Here is an example of a class that can be injected:
  ///
  /// ```dart
  /// class Greeter {
  ///   String greet(String name) => 'Hello ${name}!';
  /// }
  ///
  /// @Directive(
  ///   selector: 'greet',
  ///   providers: const [ Greeter])
  /// class HelloWorld {
  ///   final Greeter greeter;
  ///
  ///   HelloWorld(this.greeter);
  /// }
  /// ```
  final List providers;

  /// Defines the name that can be used in the template to assign this directive
  /// to a variable.
  ///
  /// ### Example
  ///
  /// ```dart
  /// @Directive(
  ///   selector: 'child-dir',
  ///   exportAs: 'child')
  /// class ChildDir {}
  ///
  /// @Component(
  ///   selector: 'main',
  ///   template: `<child-dir #c="child"></child-dir>`,
  ///   directives: const [ChildDir])
  /// class MainComponent {}
  /// ```
  final String exportAs;

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
  ///       queries: const {
  ///         'contentChildren': const ContentChildren(ChildDirective),
  ///         'viewChildren': const ViewChildren(ChildDirective),
  ///         'contentChild': const ContentChild(SingleChildDirective),
  ///         'viewChild': const ViewChild(SingleChildDirective)
  ///       },
  ///       template: '''
  ///         <child-directive></child-directive>
  ///         <single-child-directive></single-child-directive>
  ///         <ng-content></ng-content>
  ///       ''',
  ///       directives: const [ChildDirective, SingleChildDirective])
  ///     class SomeDir {
  ///       QueryList<ChildDirective> contentChildren;
  ///       QueryList<ChildDirective> viewChildren;
  ///       SingleChildDirective contentChild;
  ///       SingleChildDirective viewChild;
  ///
  ///       ngAfterContentInit() {
  ///         // contentChildren is set
  ///         // contentChild is set
  ///       }
  ///
  ///       ngAfterViewInit() {
  ///         // viewChildren is set
  ///         // viewChild is set
  ///       }
  ///     }
  ///
  final Map<String, dynamic> queries;

  const Directive(
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
/// - creates a shadow DOM for the component,
/// - loads the selected template into the shadow DOM and
/// - creates all the injectable objects configured with [providers] and
///   [viewProviders].
///
/// All template expressions and statements are then evaluated against the
/// component instance.
///
/// For details on the `@View` annotation, see [View].
///
/// ### Lifecycle hooks
///
/// When the component class implements some [lifecycle-hooks](docs/guide/lifecycle-hooks.html)
/// the callbacks are called by the change detection at defined points in time
/// during the life of the component.
class Component extends Directive {
  /// Defines the used change detection strategy.
  ///
  /// When a component is instantiated, Angular creates a change detector, which
  /// is responsible for propagating the component's bindings.
  ///
  /// The [changeDetection] property defines, whether the change detection will
  /// be checked every time or only when the component tells it to do so.
  final ChangeDetectionStrategy changeDetection;

  /// Defines the set of injectable objects that are visible to its view
  /// DOM children.
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
  /// ### Example
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

  /// Removes all whitespace except `&ngsp;` and `&nbsp;` from template if set
  /// to false.
  final bool preserveWhitespace;
  final List<String> styleUrls;
  final List<String> styles;
  final List<dynamic /* Type | List < dynamic > */ > directives;
  final List<dynamic /* Type | List < dynamic > */ > pipes;
  final ViewEncapsulation encapsulation;
  const Component(
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
      this.preserveWhitespace: true,
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

/// Metadata properties available for configuring Views.
///
/// Each Angular component requires a single `@Component` and at least one
/// `@View` annotation. The `@View` annotation specifies the HTML template to
/// use, and lists the directives that are active within the template.
///
/// When a component is instantiated, the template is loaded into the
/// component's shadow root, and the expressions and statements in the template
/// are evaluated against the component.
///
/// For details on the `@Component` annotation, see [Component].
///
/// ## Example
///
/// ```
/// @Component(
///   selector: 'greet',
///   template: 'Hello {{name}}!',
///   directives: const [GreetUser, Bold]
/// )
/// class Greet {
///   final String name;
///
///   Greet() : name = 'World';
/// }
/// ```
class View {
  /// Specifies a template URL for an Angular component.
  ///
  /// NOTE: Only one of `templateUrl` or `template` can be defined per View.
  ///
  /// <!-- TODO: what's the url relative to? -->
  final String templateUrl;

  /// Specifies an inline template for an Angular component.
  ///
  /// NOTE: Only one of `templateUrl` or `template` can be defined per View.
  final String template;

  /// Specifies stylesheet URLs for an Angular component.
  ///
  /// <!-- TODO: what's the url relative to? -->
  final List<String> styleUrls;

  /// Specifies an inline stylesheet for an Angular component.
  final List<String> styles;

  /// Specifies a list of directives that can be used within a template.
  ///
  /// Directives must be listed explicitly to provide proper component
  /// encapsulation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @Component(
  ///   selector: 'my-component',
  ///   directives: const [NgFor],
  ///   template: '''
  ///   <ul>
  ///     <li *ngFor="let item of items">{{item}}</li>
  ///   </ul>'''
  /// )
  /// class MyComponent {}
  /// ```
  final List<dynamic /* Type | List < dynamic > */ > directives;
  final List<dynamic /* Type | List < dynamic > */ > pipes;

  /// Specify how the template and the styles should be encapsulated.
  ///
  /// The default is [ViewEncapsulation#Emulated] if the view has styles,
  /// otherwise [ViewEncapsulation#None].
  final ViewEncapsulation encapsulation;
  const View(
      {String templateUrl,
      String template,
      List<dynamic /* Type | List < dynamic > */ > directives,
      List<dynamic /* Type | List < dynamic > */ > pipes,
      ViewEncapsulation encapsulation,
      List<String> styles,
      List<String> styleUrls})
      : templateUrl = templateUrl,
        template = template,
        styleUrls = styleUrls,
        styles = styles,
        directives = directives,
        pipes = pipes,
        encapsulation = encapsulation;
}

/// Declare reusable pipe function.
///
/// A "pure" pipe is only re-evaluated when either the input or any of the
/// arguments change. When not specified, pipes default to being pure.
///
class Pipe extends Injectable {
  final String name;
  final bool _pure;
  const Pipe({this.name, bool pure})
      : _pure = pure,
        super();
  bool get pure => _pure ?? true;
}

/// An annotation to specify that a constant attribute value should be injected.
///
/// The directive can inject constant string literals of host element
/// attributes.
///
/// ### Example
///
/// Suppose we have an `<input>` element and want to know its `type`.
///
/// ```html
/// <input type="text">
/// ```
///
/// A decorator can inject string literal `text` like so:
///
/// ```dart
/// @Directive(selector: 'input')
/// class InputAttrDirective {
///   InputAttrDirective(@Attribute('type') String type) {
///     // type would be 'text' in this example
///   }
/// }
/// ```
class Attribute extends DependencyMetadata {
  final String attributeName;
  const Attribute(this.attributeName) : super();
  @override
  dynamic get token {
    // Normally one would default a token to a type of an injected value but
    // here the type of a variable is "string" and we can't use primitive type
    // as a return value so we use instance of Attribute instead. This doesn't
    // matter much in practice as arguments with @Attribute annotation are
    // injected by ElementInjector that doesn't take tokens into account.
    return this;
  }

  String toString() {
    return '@Attribute($attributeName)';
  }
}

/// Declares an injectable parameter to be a live list of directives or variable
/// bindings from the content children of a directive.
///
/// ### Example
///
/// Assume that `<tabs>` component would like to get a list its children
/// `<pane>` components as shown in this example:
///
/// ```html
/// <tabs>
///   <pane title="Overview">...</pane>
///   <pane *ngFor="let o of objects" [title]="o.title">{{o.text}}</pane>
/// </tabs>
/// ```
///
/// The preferred solution is to query for `Pane` directives using this
/// decorator.
///
/// ```dart
/// @Component(selector: 'pane')
/// class Pane {
///   @Input();
///   String title;
/// }
///
/// @Component(
///  selector: 'tabs',
///  template: '''
///    <ul>
///      <li *ngFor="let pane of panes">{{pane.title}}</li>
///    </ul>
///    <ng-content></ng-content>
///  ''')
/// class Tabs {
///   final QueryList<Pane> panes;
///
///   Tabs(@Query(Pane) this.panes);
/// }
/// ```
///
/// A query can look for variable bindings by passing in a string with desired
/// binding symbol.
///
/// ### Example
///
/// ```html
/// <seeker>
///   <div #findme>...</div>
/// </seeker>
/// ```
///
/// ```dart
/// @Component(selector: 'seeker')
/// class Seeker {
///   Seeker(@Query('findme') QueryList<ElementRef> elements) {...}
/// }
/// ```
///
/// In this case the object that is injected depend on the type of the variable
/// binding. It can be an ElementRef, a directive or a component.
///
/// Passing in a comma separated list of variable bindings will query for all of
/// them.
///
/// ```html
/// <seeker>
///   <div #find-me>...</div>
///   <div #find-me-too>...</div>
/// </seeker>
/// ```
///
/// ```dart
///  @Component(selector: 'seeker')
/// class Seeker {
///   Seeker(@Query('findMe, findMeToo') QueryList<ElementRef> elements) {...}
/// }
/// ```
///
/// Configure whether query looks for direct children or all descendants of the
/// querying element, by using the `descendants` parameter.  It is set to
/// `false` by default.
///
/// ## Example
///
/// ```html
/// <container #first>
///   <item>a</item>
///   <item>b</item>
///   <container #second>
///     <item>c</item>
///   </container>
/// </container>
/// ```
///
/// When querying for items, the first container will see only `a` and `b` by
/// default, but with `Query(TextDirective, {descendants: true})` it will see
/// `c` too.
///
/// The queried directives are kept in a depth-first pre-order with respect to
/// their positions in the DOM.
///
/// Query does not look deep into any subcomponent views.
///
/// Query is updated as part of the change-detection cycle. Since change
/// detection happens after construction of a directive, QueryList will always
/// be empty when observed in the constructor.
///
/// The injected object is an unmodifiable live list. See [QueryList] for more
/// details.
class Query extends DependencyMetadata {
  final dynamic /* Type | String */ selector;

  /// whether we want to query only direct children (false) or all children
  /// (true).
  final bool descendants;
  final bool first;

  /// The DI token to read from an element that matches the selector.
  final dynamic read;
  const Query(this.selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : descendants = descendants,
        first = first,
        read = read,
        super();

  /// Always `false` to differentiate it with [ViewQuery].
  bool get isViewQuery => false;

  /// Whether this is querying for a variable binding or a directive.
  bool get isVarBindingQuery => selector is String;

  /// A list of variable bindings this is querying for.
  ///
  /// Only applicable if this is a variable bindings query.
  List get varBindings => selector.split(',');

  String toString() => '@Query($selector)';
}

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'someDir')
/// class SomeDir implements AfterContentInit {
///   @ContentChildren(ChildDirective)
///   QueryList<ChildDirective> contentChildren;
///
///   @override
///   ngAfterContentInit() {
///     // contentChildren is set
///   }
/// }
/// ```
class ContentChildren extends Query {
  const ContentChildren(dynamic /*Type | string*/ selector,
      {bool descendants: false, dynamic read: null})
      : super(selector, descendants: descendants, read: read);
}

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'someDir')
/// class SomeDir {
///   @ContentChild(ChildDirective)
///   Query<ChildDirective> contentChild;
///
///   @override
///   ngAfterContentInit() {
///     // contentChild is set
///   }
/// }
/// ```
class ContentChild extends Query {
  const ContentChild(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
}

/// Similar to [Query], but querying the component view, instead of the
/// content children.
///
/// ### Example
///
/// ```dart
/// @Component(
///   selector: 'my-component',
///   template: '''
///     <template [ngIf]="shouldShow">
///       <item> a </item>
///       <item> b </item>
///       <item> c </item>
///     </template>
///   '''
/// )
/// class MyComponent {
///   boolean shouldShow;
///
///   MyComponent(@ViewQuery(Item) QueryList<Item> items) {
///     items.changes.listen((_) => print(items.length));
///   }
/// }
/// ```
///
/// Supports the same querying parameters as [Query], except
/// `descendants`. This always queries the whole view.
///
/// As `shouldShow` is flipped between true and false, items will contain zero
/// or three items.
///
/// Specifies that a [QueryList] should be injected.
///
/// The injected object is an iterable and observable live list.  See
/// [QueryList] for more details.
class ViewQuery extends Query {
  const ViewQuery(dynamic /* Type | String */ _selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : super(_selector, descendants: descendants, first: first, read: read);

  /// Always `true` to differentiate it with [Query].
  get isViewQuery => true;

  String toString() => '@ViewQuery($selector)';
}

/// Declares a reference to multiple child elements.
///
/// The list is automatically updated when the DOM is updated.
///
/// The `ViewChildren` annotation takes an argument that specifies the elements
/// to be selected.
///
/// - If the argument is a [Type], directives or components with the type will
/// be bound.
/// - If the argument is a [String], the string is interpreted as a list of
/// comma-separated selectors.  For each selector, an element containing the
/// matching template variable (e.g. `#child`) will be bound.
///
/// View children are set before the `ngAfterViewInit` callback is called.
///
/// ### Example
///
/// With type selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '''
///     <child-cmp></child-cmp>
///     <child-cmp></child-cmp>
///     <child-cmp></child-cmp>
///   ''',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp {
///   @ViewChildren(ChildCmp)
///   QueryList<ChildCmp> children;
///
///  @override
///   ngAfterViewInit() {
///     // children are set
///     for ( var child in children ) {
///       child.doSomething();
///     }
///   }
/// }
/// ```
///
/// With string selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>')
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '''
///     <child-cmp #child1></child-cmp>
///     <child-cmp #child2></child-cmp>
///     <child-cmp #child3></child-cmp>
///   ''',
///   directives: const [ChildCmp])
/// class SomeCmp {
///   @ViewChildren('child1, child2, child3')
///   QueryList<ChildCmp> children;
///
///   @override
///   ngAfterViewInit() {
///     // children are set
///     for ( var child in children ) {
///       child.doSomething();
///     }
///   }
/// }
/// ```
class ViewChildren extends ViewQuery {
  const ViewChildren(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, read: read);
}

/// Declares a reference to a single child element.
///
/// The `ViewChildren` annotation takes an argument to select elements.
///
/// - If the argument is a [Type], a directive or a component with the type will
/// be bound.
/// - If the argument is a [String], the string is interpreted as a selector. An
/// element containing the matching template variable (e.g. `#child`) will be
/// bound.
///
/// In either case, `@ViewChild()` assigns the first (looking from above)
/// element if there are multiple matches.
///
/// View child is set before the `ngAfterViewInit` callback is called.
///
/// ### Example
///
/// With type selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '<child-cmp></child-cmp>',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp {
///   @ViewChild(ChildCmp)
///   ChildCmp child;
///
///   @override
///   ngAfterViewInit() {
///     // child is set
///     child.doSomething();
///   }
/// }
/// ```
///
/// With string selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '<child-cmp #child></child-cmp>',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp {
///   @ViewChild('child')
///   ChildCmp child;
///
///   @override
///   ngAfterViewInit() {
///     // child is set
///     child.doSomething();
///   }
/// }
/// ```
class ViewChild extends ViewQuery {
  const ViewChild(dynamic /* Type | String */ _selector, {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
}

/// Declares a data-bound input property.
///
/// Data-bound properties are automatically updated during change detection.
///
/// The [Input] annotation takes an optional parameter that specifies
/// the name used when instantiating a component in the template. When not
/// provided, the name of the decorated property is used.
///
/// ### Example
///
/// The following example creates a component with two input properties.
///
/// ```dart
/// @Component(
///    selector: 'bank-account',
///    template: '''
///      Bank Name: {{bankName}}
///      Account Id: {{id}}
///    ''')
///  class BankAccount {
///    @Input()
///    String bankName;
///
///    @Input('account-id')
///    String id;
///
///    // this property is not bound, and won't be automatically updated
///    String normalizedBankName;
///  }
///
///  @Component(
///    selector: 'app',
///    template: '''
///      <bank-account bank-name="RBC" account-id="4747"></bank-account>
///    ''',
///    directives: const [BankAccount])
///  class App {}
///  ```
class Input {
  /// Name used when instantiating a component in the template.
  final String bindingPropertyName;
  const Input([this.bindingPropertyName]);
}

/// Declares an event-bound output property.
///
/// When an output property emits an event, an event handler attached to that
/// event the template is invoked.
///
/// The [Output] annotation takes an optional parameter that specifies
/// the name used when instantiating a component in the template. When not
/// provided, the name of the decorated property is used.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'interval-dir')
/// class IntervalDir {
///   @Output()
///   final everySecond = new EventEmitter<String>();
///
///   @Output('everyFiveSeconds')
///   final every5Secs = new EventEmitter<String>();
///
///   IntervalDir() {
///     setInterval(() => everySecond.emit("event"), 1000);
///     setInterval(() => every5Secs.emit("event"), 5000);
///   }
/// }
///
/// @Component(
///   selector: 'app',
///   template: '''
///     <interval-dir
///         (everySecond)="everySecond()"
///         (everyFiveSeconds)="everyFiveSeconds()">
///     </interval-dir>
///   ''',
///   directives: const [IntervalDir])
/// class App {
///   void everySecond() {
///     print('second');
///   }
///
///   everyFiveSeconds() {
///     print('five seconds');
///   }
/// }
/// ```
class Output {
  final String bindingPropertyName;
  const Output([this.bindingPropertyName]);
}

/// Declares a host property binding.
///
/// Host property bindings are automatically checked during change detection. If
/// a binding changes, the host element of the directive is updated.
///
/// The [HostBinding] annotation takes an optional parameter that
/// specifies the property name of the host element that will be updated. When
/// not provided, the property name is used.
///
/// ### Example
///
/// The following example creates a directive that sets the `valid` and
/// `invalid` classes on the DOM element that has ngModel directive on it.
///
/// ```dart
/// @Directive(selector: '[ngModel]')
/// class NgModelStatus {
///   NgModel control;
///
///   NgModelStatus(this.control);
///
///   @HostBinding('class.valid')
///   bool get valid => return control.valid;
///
///   @HostBinding('class.invalid')
///   bool get invalid => control.invalid;
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<input [(ngModel)]="prop">',
///   directives: const [FORM_DIRECTIVES, NgModelStatus])
/// class App {
///   var prop;
///  }
/// ```
class HostBinding {
  final String hostPropertyName;
  const HostBinding([this.hostPropertyName]);
}

/// Declares a host listener.
///
/// The decorated method is invoked when the host element emits the specified
/// event.
///
/// If the decorated method returns [false], then [preventDefault] is applied
/// on the DOM event.
///
/// ### Example
///
/// The following example declares a directive that attaches a click listener to
/// the button and counts clicks.
///
/// @Directive(selector: 'button[counting]'')
/// class CountClicks {
///   int numberOfClicks = 0;
///
///   @HostListener('click', const ['$event.target'])
///   void onClick(btn) {
///     print("Button $btn, number of clicks: ${numberOfClicks++}.);
///   }
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<button counting>Increment</button>',
///   directives: const [CountClicks])
/// class App {}
/// ```
class HostListener {
  final String eventName;
  final List<String> args;
  const HostListener(this.eventName, [this.args]);
}

/// Defines an injectable whose value is given by a property on an
/// InjectorModule class.
///
/// ## Example
///
/// ```dart
/// @InjectorModule()
/// class MyModule {
///   @Provides(SomeToken)
///   String someProp = 'Hello World';
/// }
/// ```
/// @experimental
class Provides extends ProviderProperty {
  const Provides(dynamic token, {bool multi: false})
      : super(token, multi: multi);
}

/// Marks a deferred import as not needing explicit angular initialization.
class SkipAngularInitCheck {
  const SkipAngularInitCheck();
}
