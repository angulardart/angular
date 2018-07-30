@TestOn('browser')
import 'package:angular_router/angular_router.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockPlatformLocation extends Mock implements PlatformLocation {}

void main() {
  LocationStrategy locationStrategy;
  MockPlatformLocation platformLocation;

  group("empty URL doesn't overwrite query parameters", () {
    setUp(() {
      platformLocation = MockPlatformLocation();
      locationStrategy = HashLocationStrategy(platformLocation, null);
      when(platformLocation.pathname).thenReturn('/foo');
      when(platformLocation.search).thenReturn('?bar=baz');
    });

    test('on push', () {
      locationStrategy.pushState(null, null, '', '');
      verify(platformLocation.pushState(null, null, '/foo?bar=baz'));
    });

    test('on replace', () {
      locationStrategy.replaceState(null, null, '', '');
      verify(platformLocation.replaceState(null, null, '/foo?bar=baz'));
    });
  });
}
