import 'package:test/test.dart';
import 'package:angular/src/devtools.dart';

void main() {
  group('serialization/deserialization roundtrip', () {
    test('InspectorDirective', () {
      final original = InspectorDirective(name: 'TestDirective1', id: 1);

      final reconstructed = InspectorDirective.fromJson(original.toJson());

      expect(reconstructed, original);
      expect(reconstructed.hashCode, original.hashCode);
    });

    group('InspectorNode', () {
      test('with component', () {
        final original = InspectorNode(
          component: InspectorDirective(name: 'TestComponent1', id: 1),
        );

        final reconstructed = InspectorNode.fromJson(original.toJson());

        expect(reconstructed, original);
        expect(reconstructed.hashCode, original.hashCode);
      });

      test('with directives', () {
        final original = InspectorNode(
          directives: [
            InspectorDirective(name: 'TestDirective1', id: 1),
            InspectorDirective(name: 'TestDirective2', id: 2),
          ],
        );

        final reconstructed = InspectorNode.fromJson(original.toJson());

        expect(reconstructed, original);
        expect(reconstructed.hashCode, original.hashCode);
      });

      test('with children', () {
        final original = InspectorNode(
          children: [
            InspectorNode(
              component: InspectorDirective(name: 'TestComponent1', id: 1),
            ),
            InspectorNode(
              component: InspectorDirective(name: 'TestComponent2', id: 2),
            ),
          ],
        );

        final reconstructed = InspectorNode.fromJson(original.toJson());

        expect(reconstructed, original);
        expect(reconstructed.hashCode, original.hashCode);
      });
    });
  });
}
