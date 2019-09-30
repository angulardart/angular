import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

// ignore_for_file: deprecated_member_use

class AngularElementAssert extends _AbstractElementAssert {
  final Navigable element;

  AngularElementAssert(this.element, Source source) : super(source);

  AngularElementAssert get inCoreHtml {
    _inCoreHtml(element.source);
    return this;
  }

  AngularElementAssert at(String search) {
    _at(element.navigationRange.offset, search);
    return this;
  }

  AngularElementAssert inFileName(String expectedName) {
    expect(element.source.fullName, endsWith(expectedName));
    _source = element.source;
    _code = null;
    return this;
  }

  AngularElementAssert name(String expectedName) {
    expect(element, isA<NavigableString>());
    expect((element as NavigableString).string, expectedName);
    return this;
  }
}

class DartElementAssert extends _AbstractElementAssert {
  final Element element;

  DartElementAssert(this.element, Source source, String code)
      : super(source, code);

  DartElementAssert get getter {
    expect(element.kind, ElementKind.GETTER);
    return this;
  }

  DartElementAssert get inCoreHtml {
    _inCoreHtml(element.source);
    return this;
  }

  DartElementAssert get method {
    expect(element.kind, ElementKind.METHOD);
    return this;
  }

  DartElementAssert get prefix {
    expect(element.kind, ElementKind.PREFIX);
    return this;
  }

  DartElementAssert at(String search) {
    _at(element.nameOffset, search);
    return this;
  }

  DartElementAssert inFile(String path) {
    _inFile(element.source, path);
    return this;
  }
}

class InputAssert extends AngularElementAssert {
  final Input input;

  InputAssert(this.input, Source source) : super(input, source);

  @override
  InputAssert name(String expectedName) {
    expect(input.name, expectedName);
    return this;
  }
}

class LocalVariableAssert extends _AbstractElementAssert {
  final LocalVariable variable;
  final int _referenceOffset;

  LocalVariableAssert(
      this.variable, this._referenceOffset, Source htmlSource, String htmlCode)
      : super(htmlSource, htmlCode);

  LocalVariableAssert get declaration {
    expect(variable.navigationRange.offset, _referenceOffset);
    return this;
  }

  LocalVariableAssert at(String search) {
    _at(variable.navigationRange.offset, search);
    return this;
  }

  LocalVariableAssert type(String expectedTypeName) {
    expect(variable.dartVariable.type.displayName, expectedTypeName);
    return this;
  }
}

class NavigableAssert extends _AbstractElementAssert {
  final String _dartCode;
  final Source _dartSource;
  final String _htmlCode;
  final Source _htmlSource;
  final Navigable element;
  final int _referenceOffset;

  NavigableAssert(this._dartCode, this._dartSource, this._htmlCode,
      this._htmlSource, this.element, this._referenceOffset);

  AngularElementAssert get angular {
    expect(element, isNot(isA<DartElement>()));
    return AngularElementAssert(element, _dartSource);
  }

  DartElementAssert get dart {
    expect(element, isA<DartElement>());
    final dartElement = element as DartElement;
    return DartElementAssert(dartElement.element, _dartSource, _dartCode);
  }

  AngularElementAssert get input {
    expect(element, isA<Input>());
    return InputAssert(element as Input, _dartSource);
  }

  LocalVariableAssert get local {
    expect(element, isA<LocalVariable>());
    return LocalVariableAssert(
        element as LocalVariable, _referenceOffset, _htmlSource, _htmlCode);
  }

  AngularElementAssert get output {
    expect(element, isA<Output>());
    return AngularElementAssert(element as Output, _dartSource);
  }

  SelectorNameAssert get selector {
    expect(element, isA<SelectorName>());
    return SelectorNameAssert(element as SelectorName, _dartSource);
  }

  NavigableAssert inFileName(String expectedName) {
    expect(element.source.fullName, endsWith(expectedName));
    _source = element.source;
    _code = null;
    return this;
  }
}

class SelectorNameAssert extends _AbstractElementAssert {
  final SelectorName selectorName;

  SelectorNameAssert(this.selectorName, Source source) : super(source);

  SelectorNameAssert get inCoreHtml {
    _inCoreHtml(selectorName.source);
    return this;
  }

  SelectorNameAssert at(String search) {
    _at(selectorName.navigationRange.offset, search);
    return this;
  }

  SelectorNameAssert inFileName(String expectedName) {
    expect(selectorName.source.fullName, endsWith(expectedName));
    _source = selectorName.source;
    _code = null;
    return this;
  }

  SelectorNameAssert string(String expectedName) {
    expect(selectorName.string, expectedName);
    return this;
  }
}

class _AbstractElementAssert {
  Source _source;
  String _code;

  _AbstractElementAssert([this._source, this._code]);

  void _at(int actualOffset, String search) {
    _code ??= _source.contents.data;
    final offset = _code.indexOf(search);
    expect(offset, isNonNegative, reason: "|$search| in |$_code|");
    expect(actualOffset, offset);
  }

  void _inCoreHtml(Source actualSource) {
    _inUri(actualSource, 'dart:html');
  }

  void _inFile(Source actualSource, String expectedPath) {
    expect(actualSource.fullName, expectedPath);
    _source = actualSource;
    _code = null;
  }

  void _inUri(Source actualSource, String expectedUri) {
    var uri = actualSource.uri;
    expect('$uri', expectedUri);
    _source = actualSource;
    _code = null;
  }
}
