// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of angular_ast.src.token.tokens;

/// The types of tokens that can be returned by the NgStringTokenizer
enum NgSimpleTokenType {
  atSign,
  bang,
  backSlash,
  closeBanana,
  closeBrace,
  closeBracket,
  closeParen,
  closeTagStart,
  commentBegin,
  commentEnd,
  dash,
  doubleQuote,
  openTagStart,
  tagEnd,
  equalSign,
  EOF,
  forwardSlash,
  hash,
  identifier,
  mustacheBegin,
  mustacheEnd,
  openBanana,
  openBrace,
  openBracket,
  openParen,
  period,
  percent,
  singleQuote,
  star,
  text,
  unexpectedChar,
  voidCloseTag,
  whitespace,
}

/// The types of tokens that can be returned by the NgScanner.
enum NgTokenType {
  annotationPrefix,
  bananaPrefix,
  bananaSuffix,
  bindPrefix, // Not used in NgScanner.
  beforeElementDecorator,
  beforeElementDecoratorValue,
  closeElementEnd,
  closeElementStart,
  commentEnd,
  commentStart,
  commentValue,
  doubleQuote,
  elementDecorator,
  elementDecoratorValue,
  elementIdentifier,
  eventPrefix,
  eventSuffix,
  interpolationEnd,
  interpolationStart,
  interpolationValue,
  letPrefix,
  openElementEnd,
  openElementEndVoid,
  openElementStart,
  onPrefix, // Not used in NgScanner.
  propertyPrefix,
  propertySuffix,
  referencePrefix,
  singleQuote,
  templatePrefix,
  text,
  whitespace,
}
