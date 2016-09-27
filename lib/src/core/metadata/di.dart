import "package:angular2/src/core/di/metadata.dart" show DependencyMetadata;

/// An annotation to specify that a constant attribute value should be injected.
///
/// The directive can inject constant string literals of host element
/// attributes.
///
/// ## Example
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
class AttributeMetadata extends DependencyMetadata {
  final String attributeName;
  const AttributeMetadata(this.attributeName) : super();
  AttributeMetadata get token {
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
/// ## Example
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
///  '''
/// )
/// class Tabs {
///   final QueryList<Pane> panes;
///   constructor(@Query(Pane) this.panes);
/// }
/// ```
///
/// A query can look for variable bindings by passing in a string with desired
/// binding symbol.
///
/// ## Example
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
/// The injected object is an unmodifiable live list.  See [QueryList] for more
/// details.
class QueryMetadata extends DependencyMetadata {
  final dynamic /* Type | String */ selector;

  /// whether we want to query only direct children (false) or all children
  /// (true).
  final bool descendants;
  final bool first;

  /// The DI token to read from an element that matches the selector.
  final dynamic read;
  const QueryMetadata(this.selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : descendants = descendants,
        first = first,
        read = read,
        super();

  /// Always `false` to differentiate it with [ViewQueryMetadata].
  bool get isViewQuery => false;

  /// Whether this is querying for a variable binding or a directive.
  bool get isVarBindingQuery => selector is String;

  /// A list of variable bindings this is querying for.
  ///
  /// Only applicable if this is a variable bindings query.
  List get varBindings => selector.split(',');

  String toString() => '@Query($selector)';
}
// TODO: add an example after ContentChildren and ViewChildren are in master

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ## Example
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
class ContentChildrenMetadata extends QueryMetadata {
  const ContentChildrenMetadata(dynamic /* Type | String */ _selector,
      {bool descendants: false, dynamic read: null})
      : super(_selector, descendants: descendants, read: read);
}
// TODO: add an example after ContentChild and ViewChild are in master

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ## Example
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
class ContentChildMetadata extends QueryMetadata {
  const ContentChildMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
}

/// Similar to [QueryMetadata], but querying the component view, instead of the
/// content children.
///
/// ## Example
///
/// ```dart
/// @Component(
///   ...,
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
class ViewQueryMetadata extends QueryMetadata {
  const ViewQueryMetadata(dynamic /* Type | String */ _selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : super(_selector, descendants: descendants, first: first, read: read);

  /// Always `true` to differentiate it with [QueryMetadata].
  get isViewQuery => true;

  String toString() => '@ViewQuery($selector)';
}

/// Declares a list of child element references.
///
/// Angular automatically updates the list when the DOM is updated.
///
/// `ViewChildren` takes an argument to select elements.
///
/// - If the argument is a type, directives or components with the type will be
/// bound.
/// - If the argument is a string, the string is interpreted as a list of
/// comma-separated selectors.  For each selector, an element containing the
/// matching template variable (e.g. `#child`) will be bound.
///
/// View children are set before the `ngAfterViewInit` callback is called.
///
/// ## Example
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
///   template: '<p>child</p>'
/// )
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
///   directives: const [ChildCmp]
/// )
/// class SomeCmp {
///   @ViewChildren('child1,child2,child3')
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
class ViewChildrenMetadata extends ViewQueryMetadata {
  const ViewChildrenMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, read: read);
}

/// Declares a reference of child element.
///
/// `ViewChildren` takes an argument to select elements.
///
/// - If the argument is a type, a directive or a component with the type will
/// be bound.
/// - If the argument is a string, the string is interpreted as a selector. An
/// element containing the matching template variable (e.g. `#child`) will be
/// bound.
///
/// In either case, `@ViewChild()` assigns the first (looking from above)
/// element if there are multiple matches.
///
/// View child is set before the `ngAfterViewInit` callback is called.
///
/// ## Example
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
class ViewChildMetadata extends ViewQueryMetadata {
  const ViewChildMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
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
class ProviderPropertyMetadata {
  final dynamic token;
  final bool _multi;
  const ProviderPropertyMetadata(this.token, {bool multi: false})
      : _multi = multi;
  bool get multi {
    return this._multi;
  }
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
class InjectorModuleMetadata {
  final List<dynamic> _providers;
  const InjectorModuleMetadata({List<dynamic> providers: const []})
      : _providers = providers;
  List<dynamic> get providers {
    return this._providers;
  }
}
