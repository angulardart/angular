import 'package:angular/angular.dart';

const baseUrlToken = OpaqueToken('baseUrlDescription');

@Component(
  selector: 'has-opaque-tokens',
  template: '{{baseUrl}}',
  providers: [
    Provider(baseUrlToken, useValue: 'https://localhost'),
  ],
)
class HasOpaqueTokens {
  final String baseUrl;

  HasOpaqueTokens(@Inject(baseUrlToken) this.baseUrl);
}

const listOfDurationToken = OpaqueToken<List<Duration>>('listOfDuration');

@Component(
  selector: 'contains-child-component',
  template: r'''
    <div *ngIf="someValue">
      <div *ngIf="someValue">
        <injects-typed-token-from-parent></injects-typed-token-from-parent>
      </div>
    </div>
  ''',
  directives: [
    InjectsTypedTokenFromSomeParent,
    NgIf,
  ],
)
class ContainsChildComponent {
  bool someValue = true;
}

@Component(
  selector: 'injects-typed-token-from-parent',
  template: '',
)
class InjectsTypedTokenFromSomeParent {
  final List<Duration> example;

  InjectsTypedTokenFromSomeParent(@Inject(listOfDurationToken) this.example);
}
