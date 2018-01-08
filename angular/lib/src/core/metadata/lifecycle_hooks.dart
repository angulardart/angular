import 'package:angular/src/core/change_detection/change_detection_util.dart'
    show SimpleChange;

/// Lifecycle hooks are guaranteed to be called in the following order:
/// - `OnChanges` (if any bindings have changed),
/// - `OnInit` (after the first check only),
/// - `DoCheck`,
/// - `AfterContentInit`,
/// - `AfterContentChecked`,
/// - `AfterViewInit`,
/// - `AfterViewChecked`,
/// - `OnDestroy` (at the very end before destruction)
enum LifecycleHooks {
  OnInit,
  OnDestroy,
  DoCheck,
  OnChanges,
  AfterChanges,
  AfterContentInit,
  AfterContentChecked,
  AfterViewInit,
  AfterViewChecked
}

/// Implement this interface to get notified when any data-bound property of
/// your directive changes.
///
/// [ngOnChanges] is called right after the data-bound properties have been
/// checked and before view and content children are checked if at least one of
/// them has changed.
///
/// The [changes] parameter contains an entry for each changed data-bound
/// property. The key is the property name and the value is an instance of
/// [SimpleChange].
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/on_changes_component.dart (ng-on-changes)"?>
/// ```dart
/// ngOnChanges(Map<String, SimpleChange> changes) {
///   changes.forEach((String propName, SimpleChange change) {
///     String cur = JSON.encode(change.currentValue);
///     String prev = change.previousValue == null
///         ? "{}"
///         : JSON.encode(change.previousValue);
///     changeLog.add('$propName: currentValue = $cur, previousValue = $prev');
///   });
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#onchanges
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#onchanges
abstract class OnChanges {
  ngOnChanges(Map<String, SimpleChange> changes);
}

/// Implement this interface to get notified when any data-bound property of
/// your directive changes.
///
/// [ngAfterChanges] is called right after the data-bound properties have been
/// checked and before view and content children are checked if at least one of
/// them has changed.
///
abstract class AfterChanges {
  ngAfterChanges();
}

/// Implement to execute [ngOnInit] after the first change-detection completed.
///
/// [ngOnInit] is called right after the component or directive's data-bound
/// properties have been checked for the first time, and before any of its
/// children have been checked. It is normally only invoked once when the
/// directive is instantiated:
///
/// ```dart
/// @Component(
///   selector: 'user-panel',
///   directives: const [NgFor],
///   template: r'''
///     <li *ngFor="let user of users">
///       {{user}}
///     </li>
///   ''',
/// )
/// class UserPanel implements OnInit {
///   final RpcService _rpcService;
///
///   List<String> users = const [];
///
///   UserPanel(this._rpcService);
///
///   @override
///   ngOnInit() async {
///     users = await _rpcService.getUsers();
///   }
/// }
/// ```
///
/// **Warning:** As part of [crash detection][] AngularDart may execute
/// [ngOnInit] a second time if part of the application threw an exception
/// during change detection.
///
/// [crash detection]: https://github.com/dart-lang/angular/blob/master/doc/crash_detection.md#crash-safety-for-angulardart
///
abstract class OnInit {
  /// Executed after the first change detection run for a directive.
  ///
  /// _See [OnInit] for a full description._
  ngOnInit();
}

/// Implement to execute [ngOnDestroy] before your component is destroyed.
///
/// [ngOnDestroy] is invoked as AngularDart is removing the component or
/// directive from the DOM, as either it has been destroyed as a result of
/// a structural directive's request (`*ngIf` becoming `false`), or a parent
/// component is being destroyed. [ngOnDestroy] may be used to cleanup resources
/// such as [StreamSubscription]s:
///
/// ```dart
/// @Component(
///   selector: 'user-panel',
///   template: 'Online users: {{count}}',
/// )
/// class UserPanel implements OnInit, OnDestroy {
///   StreamSubscription _onlineUserSub;
///
///   int count = 0;
///
///   @override
///   ngOnInit() {
///     _onlineUserSub = onlineUsers.listen((count) => this.count = count);
///   }
///
///   @override
///   ngOnDestroy() {
///     _onlineUserSub.cancel();
///   }
/// }
/// ```
///
/// **Warning:** As part of [crash detection][] AngularDart may execute
/// [ngOnDestroy] a second time if part of the application threw an exception
/// during change detection. It is _not recommended_ to set values to `null`
/// as a result.
///
/// [crash detection]: https://github.com/dart-lang/angular/blob/master/doc/crash_detection.md#crash-safety-for-angulardart
///
abstract class OnDestroy {
  /// Executed before the directive is removed from the DOM and destroyed.
  ///
  /// _See [OnDestroy] for a full description._
  ngOnDestroy();
}

/// Implement this interface to override the default change detection algorithm
/// for your directive.
///
/// [ngDoCheck] gets called to check the changes in the directives instead of
/// the default algorithm.
///
/// The default change detection algorithm looks for differences by comparing
/// bound-property values by reference across change detection runs. When
/// [DoCheck] is implemented, the default algorithm is disabled and [ngDoCheck]
/// is responsible for checking for changes.
///
/// Implementing this interface allows improving performance by using insights
/// about the component, its implementation and data types of its properties.
///
/// Note that a directive should not implement both [DoCheck] and [OnChanges] at
/// the same time.  [ngOnChanges] would not be called when a directive
/// implements [DoCheck]. Reaction to the changes have to be handled from within
/// the [ngDoCheck] callback.
///
/// Use [KeyValueDiffers] and [IterableDiffers] to add your custom check
/// mechanisms.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/do_check_component.dart (ng-do-check)"?>
/// ```dart
/// ngDoCheck() {
///   if (hero.name != oldHeroName) {
///     changeDetected = true;
///     changeLog.add(
///         'DoCheck: Hero name changed to "${hero.name}" from "$oldHeroName"');
///     oldHeroName = hero.name;
///   }
///
///   if (power != oldPower) {
///     changeDetected = true;
///     changeLog.add('DoCheck: Power changed to "$power" from "$oldPower"');
///     oldPower = power;
///   }
///
///   if (changeDetected) {
///     noChangeCount = 0;
///   } else {
///     // log that hook was called when there was no relevant change.
///     var count = noChangeCount += 1;
///     var noChangeMsg =
///         'DoCheck called ${count}x when no change to hero or power';
///     if (count == 1) {
///       // add new "no change" message
///       changeLog.add(noChangeMsg);
///     } else {
///       // update last "no change" message
///       changeLog[changeLog.length - 1] = noChangeMsg;
///     }
///   }
///
///   changeDetected = false;
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#docheck
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#onchangeslifecycle-hooks#docheck
abstract class DoCheck {
  ngDoCheck();
}

/// Implement this interface to get notified when your directive's content has
/// been fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- projected content begins --</div>
///     <ng-content></ng-content>
///   <div>-- projected content ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>
///   ''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (hooks)"?>
/// ```dart
/// class AfterContentComponent implements AfterContentChecked, AfterContentInit {
///   String _prevHero = '';
///   String comment = '';
///
///   // Query for a CONTENT child of type `ChildComponent`
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;
///
///   ngAfterContentInit() {
///     // contentChild is set after the content has been initialized
///     _logIt('AfterContentInit');
///     _doSomething();
///   }
///
///   ngAfterContentChecked() {
///     // contentChild is updated after the content has been checked
///     if (_prevHero == contentChild?.hero) {
///       _logIt('AfterContentChecked (no change)');
///     } else {
///       _prevHero = contentChild?.hero;
///       _logIt('AfterContentChecked');
///       _doSomething();
///     }
///   }
///
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#aftercontent
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-content
abstract class AfterContentInit {
  ngAfterContentInit();
}

/// Implement this interface to get notified after every check of your
/// directive's content.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- projected content begins --</div>
///     <ng-content></ng-content>
///   <div>-- projected content ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>
///   ''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (hooks)"?>
/// ```dart
/// class AfterContentComponent implements AfterContentChecked, AfterContentInit {
///   String _prevHero = '';
///   String comment = '';
///
///   // Query for a CONTENT child of type `ChildComponent`
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;
///
///   ngAfterContentInit() {
///     // contentChild is set after the content has been initialized
///     _logIt('AfterContentInit');
///     _doSomething();
///   }
///
///   ngAfterContentChecked() {
///     // contentChild is updated after the content has been checked
///     if (_prevHero == contentChild?.hero) {
///       _logIt('AfterContentChecked (no change)');
///     } else {
///       _prevHero = contentChild?.hero;
///       _logIt('AfterContentChecked');
///       _doSomething();
///     }
///   }
///
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#aftercontent
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-content
abstract class AfterContentChecked {
  ngAfterContentChecked();
}

/// Implement this interface to get notified when your component's view has been
/// fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- child view begins --</div>
///     <my-child-view></my-child-view>
///   <div>-- child view ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (hooks)"?>
/// ```dart
/// class AfterViewComponent implements AfterViewChecked, AfterViewInit {
///   var _prevHero = '';
///
///   // Query for a VIEW child of type `ChildViewComponent`
///   @ViewChild(ChildViewComponent)
///   ChildViewComponent viewChild;
///
///   ngAfterViewInit() {
///     // viewChild is set after the view has been initialized
///     _logIt('AfterViewInit');
///     _doSomething();
///   }
///
///   ngAfterViewChecked() {
///     // viewChild is updated after the view has been checked
///     if (_prevHero == viewChild.hero) {
///       _logIt('AfterViewChecked (no change)');
///     } else {
///       _prevHero = viewChild.hero;
///       _logIt('AfterViewChecked');
///       _doSomething();
///     }
///   }
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#afterview
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-view
abstract class AfterViewInit {
  ngAfterViewInit();
}

/// Implement this interface to get notified after every check of your
/// component's view.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- child view begins --</div>
///     <my-child-view></my-child-view>
///   <div>-- child view ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (hooks)"?>
/// ```dart
/// class AfterViewComponent implements AfterViewChecked, AfterViewInit {
///   var _prevHero = '';
///
///   // Query for a VIEW child of type `ChildViewComponent`
///   @ViewChild(ChildViewComponent)
///   ChildViewComponent viewChild;
///
///   ngAfterViewInit() {
///     // viewChild is set after the view has been initialized
///     _logIt('AfterViewInit');
///     _doSomething();
///   }
///
///   ngAfterViewChecked() {
///     // viewChild is updated after the view has been checked
///     if (_prevHero == viewChild.hero) {
///       _logIt('AfterViewChecked (no change)');
///     } else {
///       _prevHero = viewChild.hero;
///       _logIt('AfterViewChecked');
///       _doSomething();
///     }
///   }
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#afterview
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-view
abstract class AfterViewChecked {
  ngAfterViewChecked();
}
