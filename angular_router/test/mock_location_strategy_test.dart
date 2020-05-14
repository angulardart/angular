import 'package:test/test.dart';
import 'package:angular_router/src/location/testing/mock_location_strategy.dart';

void main() {
  group('$MockLocationStrategy', () {
    group('back', () {
      test('after multiple replace', () {
        final strategy = MockLocationStrategy();
        strategy.pushState(null, 'First page', '/first', '');
        strategy.pushState(null, 'Second page', '/second', '');
        strategy.replaceState(null, 'Replace 1', '/replace1', '');
        strategy.replaceState(null, 'Replace 1', '/replace1', '');

        strategy.back();

        expect(strategy.path(), '/first');
        expect(strategy.urlChanges, ['/first']);
      });

      test('to replaced url', () {
        final strategy = MockLocationStrategy();
        strategy.pushState(null, 'First page', '/first', '');
        strategy.replaceState(null, 'Replace 1', '/replace1', '');
        strategy.pushState(null, 'Second page', '/second', '');

        strategy.back();

        expect(strategy.path(), '/replace1');
        expect(strategy.urlChanges, ['/first', 'replace: /replace1']);
      });

      test('after exclusively pushes', () {
        final strategy = MockLocationStrategy();
        strategy.pushState(null, 'First page', '/first', '');
        strategy.pushState(null, 'Second page', '/second', '');

        strategy.back();

        expect(strategy.path(), '/first');
        expect(strategy.urlChanges, ['/first']);
      });
    });
  });
}
