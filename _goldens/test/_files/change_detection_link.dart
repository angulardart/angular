import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';

/// This demonstrates the code generated to implement `@changeDetectionLink`.
///
/// In practice, you'd only use `@changeDetectionLink` if this component were
/// passing a [ComponentFactory] that loads another Default component to its
/// OnPush descendants. However, this isn't needed to generate the code in
/// interest.
@Component(
  selector: 'default-ancestor',
  template: '''
    <on-push-link>
    </on-push-link>
  ''',
  directives: [OnPushLink],
)
class DefaultAncestor {}

@changeDetectionLink
@Component(
  selector: 'on-push-link',
  template: '''
    <template #container></template>
    <ng-container *ngIf="isVisible">
      <template #embeddedContainer></template>
    </ng-container>
    <nested-on-push></nested-on-push>
    <nested-on-push-link></nested-on-push-link>
    <nested-on-push-link *ngIf="isVisible"></nested-on-push-link>
  ''',
  directives: [
    NestedOnPush,
    NestedOnPushLink,
    NgIf,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushLink {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef container;

  @ViewChild('embeddedContainer', read: ViewContainerRef)
  ViewContainerRef embeddedContainer;
}

// Should not be linked.
@Component(
  selector: 'nested-on-push',
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class NestedOnPush {}

@changeDetectionLink
@Component(
  selector: 'nested-on-push-link',
  template: '''
    <template #container></template>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class NestedOnPushLink {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef container;
}
