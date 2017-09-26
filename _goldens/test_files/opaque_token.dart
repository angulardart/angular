import 'package:angular/angular.dart';

const baseUrlToken = const OpaqueToken('baseUrlDescription');

@Component(
  selector: 'has-opaque-tokens',
  template: '{{baseUrl}}',
  providers: const [
    const Provider(baseUrlToken, useValue: 'https://localhost'),
  ],
)
class HasOpaqueTokens {
  final String baseUrl;

  HasOpaqueTokens(@Inject(baseUrlToken) this.baseUrl);
}
