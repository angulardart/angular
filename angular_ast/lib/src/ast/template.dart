// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

const _listEquals = const ListEquality<dynamic>();

/// Represents an embedded template (i.e. is not directly rendered in DOM).
///
/// It shares many properties with an [ElementAst], but is not one. It may be
/// considered invalid to a `<template>` without any [properties] or
/// [references].
///
/// Clients should not extend, implement, or mix-in this class.
abstract class EmbeddedTemplateAst implements StandaloneTemplateAst {
  factory EmbeddedTemplateAst({
    List<AttributeAst> attributes,
    List<StandaloneTemplateAst> childNodes,
    List<EventAst> events,
    List<PropertyAst> properties,
    List<ReferenceAst> references,
    List<LetBindingAst> letBindings,
    bool hasDeferredComponent,
  }) = _SyntheticEmbeddedTemplateAst;

  factory EmbeddedTemplateAst.from(
    TemplateAst origin, {
    List<AttributeAst> attributes,
    List<StandaloneTemplateAst> childNodes,
    List<EventAst> events,
    List<PropertyAst> properties,
    List<ReferenceAst> references,
    List<LetBindingAst> letBindings,
    bool hasDeferredComponent,
  }) = _SyntheticEmbeddedTemplateAst.from;

  factory EmbeddedTemplateAst.parsed(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken endToken, {
    CloseElementAst closeComplement,
    List<AttributeAst> attributes,
    List<StandaloneTemplateAst> childNodes,
    List<EventAst> events,
    List<PropertyAst> properties,
    List<ReferenceAst> references,
    List<LetBindingAst> letBindings,
    bool hasDeferredComponent,
  }) = _ParsedEmbeddedTemplateAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitEmbeddedTemplate(this, context);
  }

  /// Attributes.
  ///
  /// Within a `<template>` tag, it may be assumed that this is a directive.
  List<AttributeAst> get attributes;

  /// Events.
  ///
  /// Within a `<template>` tag, it may be assumed that this is a directive.
  List<EventAst> get events;

  /// Property assignments.
  ///
  /// For an embedded template, it may be assumed that all of this will be one
  /// or more structural directives (i.e. like `ngForOf`), as the template
  /// itself does not have properties.
  List<PropertyAst> get properties;

  /// References to the template.
  ///
  /// Unlike a reference to a DOM element, this will be a `TemplateRef`.
  List<ReferenceAst> get references;

  /// `let-` binding defined within a template.
  List<LetBindingAst> get letBindings;

  /// A flag to indicate that this template contains a `Component` which should
  /// be deferred-loaded.
  bool get hasDeferredComponent;

  /// </template> that is paired to this <template>.
  CloseElementAst get closeComplement;
  set closeComplement(CloseElementAst closeComplement);

  @override
  bool operator ==(Object o) {
    if (o is EmbeddedTemplateAst) {
      return closeComplement == o.closeComplement &&
          _listEquals.equals(attributes, o.attributes) &&
          _listEquals.equals(events, o.events) &&
          _listEquals.equals(properties, o.properties) &&
          _listEquals.equals(childNodes, o.childNodes) &&
          _listEquals.equals(references, o.references) &&
          _listEquals.equals(letBindings, o.letBindings) &&
          hasDeferredComponent == o.hasDeferredComponent;
    }
    return false;
  }

  @override
  int get hashCode {
    return hashObjects([
      closeComplement,
      _listEquals.hash(attributes),
      _listEquals.hash(events),
      _listEquals.hash(childNodes),
      _listEquals.hash(properties),
      _listEquals.hash(references),
      _listEquals.hash(letBindings),
      hasDeferredComponent,
    ]);
  }

  @override
  String toString() {
    final buffer = new StringBuffer('$EmbeddedTemplateAst{ ');
    if (attributes.isNotEmpty) {
      buffer
        ..write('attributes=')
        ..writeAll(attributes, ', ')
        ..write(' ');
    }
    if (events.isNotEmpty) {
      buffer
        ..write('events=')
        ..writeAll(events, ', ')
        ..write(' ');
    }
    if (properties.isNotEmpty) {
      buffer
        ..write('properties=')
        ..writeAll(properties, ', ')
        ..write(' ');
    }
    if (references.isNotEmpty) {
      buffer
        ..write('references=')
        ..writeAll(references, ', ')
        ..write(' ');
    }
    if (letBindings.isNotEmpty) {
      buffer
        ..write('letBindings=')
        ..writeAll(letBindings, ', ')
        ..write(' ');
    }
    if (hasDeferredComponent) {
      buffer.write('deferred ');
    }
    if (childNodes.isNotEmpty) {
      buffer
        ..write('childNodes=')
        ..writeAll(childNodes, ', ')
        ..write(' ');
    }
    if (closeComplement != null) {
      buffer..write('closeComplement=')..write(closeComplement)..write(' ');
    }
    return (buffer..write('}')).toString();
  }
}

class _ParsedEmbeddedTemplateAst extends TemplateAst with EmbeddedTemplateAst {
  _ParsedEmbeddedTemplateAst(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken endToken, {
    this.closeComplement,
    this.attributes: const [],
    this.childNodes: const [],
    this.events: const [],
    this.properties: const [],
    this.references: const [],
    this.letBindings: const [],
    this.hasDeferredComponent: false,
  }) : super.parsed(beginToken, endToken, sourceFile);

  @override
  final List<AttributeAst> attributes;

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<EventAst> events;

  @override
  final List<PropertyAst> properties;

  @override
  final List<ReferenceAst> references;

  @override
  final List<LetBindingAst> letBindings;

  @override
  final bool hasDeferredComponent;

  @override
  CloseElementAst closeComplement;
}

class _SyntheticEmbeddedTemplateAst extends SyntheticTemplateAst
    with EmbeddedTemplateAst {
  _SyntheticEmbeddedTemplateAst({
    this.attributes: const [],
    this.childNodes: const [],
    this.events: const [],
    this.properties: const [],
    this.references: const [],
    this.letBindings: const [],
    this.hasDeferredComponent: false,
  }) : closeComplement = new CloseElementAst('template');

  _SyntheticEmbeddedTemplateAst.from(
    TemplateAst origin, {
    this.attributes: const [],
    this.childNodes: const [],
    this.events: const [],
    this.properties: const [],
    this.references: const [],
    this.letBindings: const [],
    this.hasDeferredComponent: false,
  })  : closeComplement = new CloseElementAst('template'),
        super.from(origin);

  @override
  final List<AttributeAst> attributes;

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<EventAst> events;

  @override
  final List<PropertyAst> properties;

  @override
  final List<ReferenceAst> references;

  @override
  final List<LetBindingAst> letBindings;

  @override
  final bool hasDeferredComponent;

  @override
  CloseElementAst closeComplement;
}
