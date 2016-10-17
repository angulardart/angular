import 'package:angular2/src/core/change_detection/change_detection.dart';

import 'metadata/di.dart';
import 'metadata/directives.dart';
import 'metadata/view.dart';

export './metadata/view.dart' hide VIEW_ENCAPSULATION_VALUES;
export 'metadata/di.dart';
export 'metadata/directives.dart';
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
class Directive extends DirectiveMetadata {
  const Directive(
      {String selector,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      List providers,
      String exportAs,
      Map<String, dynamic> queries})
      : super(
            selector: selector,
            inputs: inputs,
            outputs: outputs,
            host: host,
            providers: providers,
            exportAs: exportAs,
            queries: queries);
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
class Component extends ComponentMetadata {
  const Component(
      {String selector,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      List providers,
      String exportAs,
      String moduleId,
      Map<String, dynamic> queries,
      List viewProviders,
      ChangeDetectionStrategy changeDetection,
      String templateUrl,
      String template,
      bool preserveWhitespace,
      dynamic directives,
      dynamic pipes,
      ViewEncapsulation encapsulation,
      List<String> styles,
      List<String> styleUrls})
      : super(
            selector: selector,
            inputs: inputs,
            outputs: outputs,
            host: host,
            providers: providers,
            exportAs: exportAs,
            moduleId: moduleId,
            viewProviders: viewProviders,
            queries: queries,
            changeDetection: changeDetection,
            templateUrl: templateUrl,
            template: template,
            preserveWhitespace: preserveWhitespace,
            directives: directives,
            pipes: pipes,
            encapsulation: encapsulation,
            styles: styles,
            styleUrls: styleUrls);
}

/// See: [View] for docs.
class View extends ViewMetadata {
  const View(
      {String templateUrl,
      String template,
      dynamic directives,
      dynamic pipes,
      ViewEncapsulation encapsulation,
      List<String> styles,
      List<String> styleUrls})
      : super(
            templateUrl: templateUrl,
            template: template,
            directives: directives,
            pipes: pipes,
            encapsulation: encapsulation,
            styles: styles,
            styleUrls: styleUrls);
}

/// See: [PipeMetadata] for docs.
class Pipe extends PipeMetadata {
  const Pipe({name, pure}) : super(name: name, pure: pure);
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
class Attribute extends AttributeMetadata {
  const Attribute(String attributeName) : super(attributeName);
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
@Deprecated("Use ContentChildren/ContentChild instead")
class Query extends QueryMetadata {
  const Query(dynamic /*Type | string*/ selector,
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
class ContentChildren extends ContentChildrenMetadata {
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
class ContentChild extends ContentChildMetadata {
  const ContentChild(dynamic /*Type | string*/ selector, {dynamic read: null})
      : super(selector, read: read);
}

/// Similar to [QueryMetadata], but querying the component view, instead of the
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
/// Supports the same querying parameters as [QueryMetadata], except
/// `descendants`. This always queries the whole view.
///
/// As `shouldShow` is flipped between true and false, items will contain zero
/// or three items.
///
/// Specifies that a [QueryList] should be injected.
///
/// The injected object is an iterable and observable live list.  See
/// [QueryList] for more details.
@Deprecated("Use ViewChildren/ViewChild instead")
class ViewQuery extends ViewQueryMetadata {
  const ViewQuery(dynamic /*Type | string*/ selector, {dynamic read: null})
      : super(selector, descendants: true, read: read);
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
class ViewChildren extends ViewChildrenMetadata {
  const ViewChildren(dynamic /*Type | string*/ selector, {dynamic read: null})
      : super(selector, read: read);
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
class ViewChild extends ViewChildMetadata {
  const ViewChild(dynamic /*Type | string*/ selector, {dynamic read: null})
      : super(selector, read: read);
}

/// Declares a data-bound input property.
///
/// Data-bound properties are automatically updated during change detection.
///
/// The [InputMetadata] annotation takes an optional parameter that specifies
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
class Input extends InputMetadata {
  const Input([String bindingPropertyName]) : super(bindingPropertyName);
}

/// Declares an event-bound output property.
///
/// When an output property emits an event, an event handler attached to that
/// event the template is invoked.
///
/// The [OutputMetadata] annotation takes an optional parameter that specifies
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
class Output extends OutputMetadata {
  const Output([String bindingPropertyName]) : super(bindingPropertyName);
}

/// Declares a host property binding.
///
/// Host property bindings are automatically checked during change detection. If
/// a binding changes, the host element of the directive is updated.
///
/// The [HostBindingMetadata] annotation takes an optional parameter that
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
class HostBinding extends HostBindingMetadata {
  const HostBinding([String hostPropertyName]) : super(hostPropertyName);
}

/// Declares a host listener.
///
/// The decoreated method is invoked when the host element emits the specified
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
class HostListener extends HostListenerMetadata {
  const HostListener(String eventName, [List<String> args])
      : super(eventName, args);
}

/// Defines an injector module from which an injector can be generated.
///
/// ## Example
///
/// ```dart
/// @InjectorModule(
///   providers: const [SomeService]
/// )
/// class MyModule {}
///
/// ```
/// @experimental
class InjectorModule extends InjectorModuleMetadata {
  const InjectorModule({List providers: const []})
      : super(providers: providers);
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
class Provides extends ProviderPropertyMetadata {
  const Provides(dynamic token, {bool multi: false})
      : super(token, multi: multi);
}

/// Marks a deferred import as not needing explicit angular initialization.
class SkipAngularInitCheck {
  const SkipAngularInitCheck();
}
