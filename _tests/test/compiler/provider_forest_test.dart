@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular/src/compiler/view_compiler/provider_forest.dart';
import 'package:angular/src/compiler/output/output_ast.dart' as o;

void main() {
  final a = ProviderInstance([], o.NULL_EXPR);
  final b = ProviderInstance([], o.NULL_EXPR);
  final c = ProviderInstance([], o.NULL_EXPR);
  final d = ProviderInstance([], o.NULL_EXPR);

  test('expanding nothing should yield nothing', () {
    expandEmptyNodes([], []);
  });

  group('expanding empty nodes', () {
    test('should yield nothing', () {
      expandEmptyNodes([ProviderNode(0, 10)], []);
    });

    test('should yield the children', () {
      expandEmptyNodes([
        ProviderNode(0, 10, children: [
          ProviderNode(1, 5, providers: [a, b]),
          ProviderNode(6, 10, providers: [c]),
        ]),
        ProviderNode(11, 20, children: [
          ProviderNode(13, 14, children: [
            ProviderNode(14, 14, providers: [d]),
          ]),
        ]),
      ], [
        ProviderNode(1, 5, providers: [a, b]),
        ProviderNode(6, 10, providers: [c]),
        ProviderNode(14, 14, providers: [d]),
      ]);
    });
  });

  group('expanding non-empty nodes', () {
    test('should do nothing', () {
      expandEmptyNodes([
        ProviderNode(0, 10, providers: [a, b])
      ], [
        ProviderNode(0, 10, providers: [a, b])
      ]);
    });

    test('should remove empty children', () {
      expandEmptyNodes([
        ProviderNode(0, 10, providers: [
          a,
          b,
        ], children: [
          ProviderNode(1, 5, children: [
            ProviderNode(3, 3),
          ]),
          ProviderNode(6, 8),
        ])
      ], [
        ProviderNode(0, 10, providers: [a, b]),
      ]);
    });

    test('should remove empty intermediate nodes', () {
      expandEmptyNodes([
        ProviderNode(4, 16, providers: [
          a
        ], children: [
          ProviderNode(5, 16, children: [
            ProviderNode(8, 10, providers: [b, c]),
          ]),
        ]),
      ], [
        ProviderNode(4, 16, providers: [
          a
        ], children: [
          ProviderNode(8, 10, providers: [b, c]),
        ]),
      ]);
    });
  });
}

void expandEmptyNodes(List<ProviderNode> input, List<ProviderNode> expected) {
  final output = ProviderForest.expandEmptyNodes(input);
  expect(output, expected);
}
