import 'package:test/test.dart';
import 'package:angular/src/devtools/error.dart';
import 'package:angular/src/devtools/reference_counter.dart';

final throwsDevToolsError = throwsA(isA<DevToolsError>());

void main() {
  final referenceCounter = ReferenceCounter<Object>();

  tearDown(referenceCounter.dispose);

  test('should dispose all groups', () {
    final object = Object();

    // Add object to multiple groups.
    final id = referenceCounter.toId(object, 'group-1');
    referenceCounter
      ..toId(object, 'group-2')
      ..toId(object, 'group-3');

    // Dispose all groups.
    referenceCounter.dispose();

    // Object is released.
    expect(() => referenceCounter.toObject(id), throwsDevToolsError);
  });

  test('should return consistent ID for object added multiple times', () {
    final object = Object();
    final group = 'group';
    final id = referenceCounter.toId(object, group);
    expect(referenceCounter.toId(object, group), id);
  });

  test('should only count reference from a group once', () {
    final object = Object();
    final group = 'group';
    final id = referenceCounter.toId(object, group);

    // Reference the same object multiple times, then dispose the group.
    referenceCounter
      ..toId(object, group)
      ..toId(object, group)
      ..disposeGroup(group);

    // Despite multiple references, object is released when group is disposed.
    expect(() => referenceCounter.toObject(id), throwsDevToolsError);
  });

  test('should share object ID between multiple groups', () {
    final object = Object();
    final group1 = 'group-1';
    final group2 = 'group-2';
    final group3 = 'group-3';

    // All references to an object share the same ID.
    final id = referenceCounter.toId(object, group1);
    expect(referenceCounter.toId(object, group2), id);
    expect(referenceCounter.toId(object, group3), id);

    // Dispose two of three groups referencing object.
    referenceCounter.disposeGroup(group1);
    referenceCounter.disposeGroup(group2);

    // Object is still retained by third group.
    expect(referenceCounter.toObject(id), object);

    // Dispose third group.
    referenceCounter.disposeGroup(group3);

    // Object is released.
    expect(() => referenceCounter.toObject(id), throwsDevToolsError);
  });

  test('should produce a unique ID for each distinct object', () {
    final a = Object();
    final b = Object();
    final c = Object();
    final group = 'group';

    final aId = referenceCounter.toId(a, group);
    final bId = referenceCounter.toId(b, group);
    final cId = referenceCounter.toId(c, group);

    expect(aId, isNot(bId));
    expect(aId, isNot(cId));
    expect(bId, isNot(cId));
  });

  test('should only release objects with no remaining references', () {
    final a = Object();
    final b = Object();
    final c = Object();
    final d = Object();

    final group1 = 'group-1';
    final group2 = 'group-2';

    final aId = referenceCounter.toId(a, group1);
    final bId = referenceCounter.toId(b, group1);
    final cId = referenceCounter.toId(c, group2);
    final dId = referenceCounter.toId(d, group1);
    expect(dId, referenceCounter.toId(d, group2));

    referenceCounter.disposeGroup(group1);
    expect(() => referenceCounter.toObject(aId), throwsDevToolsError);
    expect(() => referenceCounter.toObject(bId), throwsDevToolsError);
    expect(referenceCounter.toObject(cId), c);
    expect(referenceCounter.toObject(dId), d);

    referenceCounter.disposeGroup(group2);
    expect(() => referenceCounter.toObject(cId), throwsDevToolsError);
    expect(() => referenceCounter.toObject(dId), throwsDevToolsError);
  });
}
