// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/angular_ast.dart';
import 'package:test/test.dart';

void main() {
  // DesugarVisitor is tested by parser_test.dart
  var visitor = const HumanizingTemplateAstVisitor();

  test('should humanize a simple template and preserve inner spaces', () {
    var templateString = '<button [title]="aTitle">Hello {{name}}</button>';
    var template = parse(
      templateString,
      sourceUrl: '/test/visitor_test.dart#inline',
    );
    expect(
      template.map((t) => t.accept(visitor)).join(''),
      equals(templateString),
    );
  });

  test('should humanize a simple template *with* de-sugaring applied', () {
    var template = parse(
        '<widget *ngIf="someValue" [(value)]="value"></widget>',
        sourceUrl: '/test/visitor_test.dart#inline',
        toolFriendlyAst: false,
        desugar: true);
    expect(
      template.map((t) => t.accept(visitor)).join(''),
      equalsIgnoringWhitespace(r'''
        <template [ngIf]="someValue"><widget (valueChange)="value = $event" [value]="value"></widget></template>
      '''),
    );
  });
}
