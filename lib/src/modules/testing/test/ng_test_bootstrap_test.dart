import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/modules/testing/lib/src/ng_test_bootstrap.dart';
import 'package:test/test.dart';

void main() {
  group('ngTestBootstrap', () {
    Element rootElement;

    setUp(() {
      rootElement = new Element.tag('root');
    });

    test('should load a new Angular instance', () async {
      await ngTestBootstrap(NgTestBootstrapTestComponent, rootElement);
      expect(rootElement.text, contains('Hello World'));
    });

    test('should call the `onLoad` callback before change detection', () async {
      await ngTestBootstrap(
        NgTestBootstrapTestComponent,
        rootElement,
        onLoad: (component) {
          component.place = 'Solar System';
          expect(rootElement.text, isEmpty);
        },
      );
      expect(rootElement.text, contains('Hello Solar System'));
    });

    test('should use `userProviders` at runtime', () async {
      await ngTestBootstrap(
        NgTestBootstrapTestComponent,
        rootElement,
        userProviders: const [Formatter],
      );
      expect(rootElement.text, contains('Hello WORLD'));
    });
  });
}

@Component(
  selector: 'ng-test-bootstrap-test',
  template: 'Hello {{placeFormatted}}',
)
class NgTestBootstrapTestComponent {
  final Formatter _formatter;

  NgTestBootstrapTestComponent(@Optional() this._formatter);

  String place = 'World';

  String get placeFormatted {
    return _formatter != null ? _formatter.format(place) : place;
  }
}

@Injectable()
class Formatter {
  const Formatter();

  String format(String input) => input.toUpperCase();
}
