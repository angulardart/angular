@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

// See https://github.com/dart-lang/angular/issues/1538.
void main() {
  test('should disallow @deferred on a `<template>` element', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'example',
        directives: [DeferMe],
        template: r'''
          <template @deferred>
            <defer-me></defer-me>
          </template>
        ''',
      )
      class Example {}

      @Component(
        selector: 'defer-me',
        template: '',
      )
      class DeferMe {}
    """, errors: [
      contains('Invalid @deferred annotation'),
    ]);
  });

  test('should disallow @deferred with a structural directive', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'example',
        directives: [DeferMe, NgIf],
        template: r'''
          <defer-me *ngIf="true" @deferred></defer-me>
        ''',
      )
      class Example {}

      @Component(
        selector: 'defer-me',
        template: '',
      )
      class DeferMe {}
    """, errors: [
      contains('Invalid @deferred annotation'),
    ]);
  });
}
