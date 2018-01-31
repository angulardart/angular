import 'package:angular/angular.dart';

const baseUrlToken = const OpaqueToken('baseUrlDescription');

@Component(
  selector: 'has-opaque-tokens',
  template: '{{baseUrl}}',
  providers: const [
    const Provider(baseUrlToken, useValue: 'https://localhost'),
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HasOpaqueTokens {
  final String baseUrl;

  HasOpaqueTokens(@Inject(baseUrlToken) this.baseUrl);
}

const listOfDurationToken = const OpaqueToken<List<Duration>>('listOfDuration');

@Component(
  selector: 'contains-child-component',
  template: r'''
    <div *ngIf="someValue">
      <div *ngIf="someValue">
        <injects-typed-token-from-parent></injects-typed-token-from-parent>
      </div>
    </div>
  ''',
  directives: const [
    InjectsTypedTokenFromSomeParent,
    NgIf,
  ],
  visibility: Visibility.local,
)
class ContainsChildComponent {
  bool someValue = true;
}

@Component(
  selector: 'injects-typed-token-from-parent',
  template: '',
  visibility: Visibility.local,
)
class InjectsTypedTokenFromSomeParent {
  final List<Duration> example;

  InjectsTypedTokenFromSomeParent(@Inject(listOfDurationToken) this.example);
}
