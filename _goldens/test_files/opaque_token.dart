import 'package:angular/angular.dart';

const baseUrlToken = const OpaqueToken('baseUrlDescription');

@Component(
  selector: 'has-opaque-tokens',
  template: '{{baseUrl}}',
  providers: const [
    const Provider(baseUrlToken, useValue: 'https://localhost'),
  ],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class HasOpaqueTokens {
  final String baseUrl;

  HasOpaqueTokens(@Inject(baseUrlToken) this.baseUrl);
}
