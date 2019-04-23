import 'package:analyzer/src/summary/api_signature.dart';
import 'package:angular_analyzer_plugin/src/file_tracker.dart';
import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileTrackerTest);
  });
}

@reflectiveTest
class FileTrackerTest {
  FileTracker _fileTracker;
  _FileHasherMock _fileHasher;
  _AngularOptionsMock _options;

  void setUp() {
    _fileHasher = _FileHasherMock();
    _options = _AngularOptionsMock();
    _fileTracker = FileTracker(_fileHasher, _options);

    when(_options.customTagNames).thenReturn(<String>[]);
  }

  // ignore: non_constant_identifier_names
  void test_dartHasTemplate() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getHtmlPathsReferencedByDart("foo.dart"),
        equals(["foo.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_dartHasTemplates() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html", "foo_bar.html"]);
    expect(_fileTracker.getHtmlPathsReferencedByDart("foo.dart"),
        equals(["foo.html", "foo_bar.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_dartSignature_includesCustomTagNames() async {
    _fileTracker.setDartHasTemplate("foo.dart", true);

    final fooDartElementSignature = '1';
    when(_fileHasher.getUnitElementSignature("foo.dart"))
        .thenAnswer((_) async => fooDartElementSignature);
    when(_options.customTagNames).thenReturn(['foo', 'bar']);
    when(_options.customEventsHashString).thenReturn('');

    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addString(fooDartElementSignature)
      ..addString('t:foo')
      ..addString('t:bar');

    expect((await _fileTracker.getDartSignature("foo.dart")).toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_getContentHashIsSalted() {
    final fooHtmlSignature = ApiSignature()..addInt(1);
    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addBytes(fooHtmlSignature.toByteList());
    when(_fileHasher.getContentHash("foo.html")).thenReturn(fooHtmlSignature);
    expect(_fileTracker.getContentSignature("foo.html").toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_getUnitElementSignatureIsSalted() async {
    final fooDartElementSignature = '1';
    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addString(fooDartElementSignature);
    when(_fileHasher.getUnitElementSignature("foo.dart"))
        .thenAnswer((_) async => fooDartElementSignature);
    expect((await _fileTracker.getUnitElementSignature("foo.dart")).toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_htmlAffectingDart() {
    _fileTracker
      ..setDartHasTemplate("foo.dart", true)
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getHtmlPathsAffectingDart("foo.dart"),
        equals(["bar.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlAffectingDartEmpty() {
    expect(_fileTracker.getHtmlPathsAffectingDart("foo.dart"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlAffectingDartEmptyNoImportedDart() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getHtmlPathsAffectingDart("foo.dart"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlAffectingDartEmptyNotDartTemplate() {
    _fileTracker
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getHtmlPathsAffectingDart("foo.dart"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDart() {
    _fileTracker
      ..setDartHasTemplate("foo.dart", true)
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getDartPathsAffectedByHtml("bar.html"),
        equals(["foo.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartEmpty() {
    expect(_fileTracker.getDartPathsAffectedByHtml("foo.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartEmptyNoImportedDart() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getDartPathsAffectedByHtml("foo.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartEmptyNotDartTemplate() {
    _fileTracker
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getDartPathsAffectedByHtml("bar.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartGetSignature() async {
    _fileTracker
      ..setDartHasTemplate("foo.dart", true)
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);

    final fooDartElementSignature = '1';
    final barHtmlSignature = ApiSignature()..addInt(2);

    when(_fileHasher.getContentHash("bar.html")).thenReturn(barHtmlSignature);
    when(_fileHasher.getUnitElementSignature("foo.dart"))
        .thenAnswer((_) async => fooDartElementSignature);
    when(_options.customEventsHashString).thenReturn('');

    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addString(fooDartElementSignature)
      ..addBytes(barHtmlSignature.toByteList());

    expect((await _fileTracker.getDartSignature("foo.dart")).toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartMultiple() {
    _fileTracker
      ..setDartHasTemplate("foo.dart", true)
      ..setDartImports("foo.dart", ["bar.dart", "baz.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html", "bar_b.html"])
      ..setDartHtmlTemplates("baz.dart", ["baz.html", "baz_b.html"]);
    expect(_fileTracker.getDartPathsAffectedByHtml("bar.html"),
        equals(["foo.dart"]));
    expect(_fileTracker.getDartPathsAffectedByHtml("bar_b.html"),
        equals(["foo.dart"]));
    expect(_fileTracker.getDartPathsAffectedByHtml("baz.html"),
        equals(["foo.dart"]));
    expect(_fileTracker.getDartPathsAffectedByHtml("baz_b.html"),
        equals(["foo.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasDartNotGrandchildren() {
    _fileTracker
      ..setDartHasTemplate("foo.dart", true)
      ..setDartImports("foo.dart", ["child.dart"])
      ..setDartHtmlTemplates("child.dart", ["child.html"])
      ..setDartImports("child.dart", ["grandchild.dart"])
      ..setDartHtmlTemplates("grandchild.dart", ["grandchild.html"]);
    expect(_fileTracker.getDartPathsAffectedByHtml("child.html"),
        equals(["foo.dart"]));
    expect(
        _fileTracker.getDartPathsAffectedByHtml("grandchild.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtml() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getHtmlPathsReferencingHtml("bar.html"),
        equals(["foo.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlButNotGrandchildren() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartImports("foo.dart", ["child.dart"])
      ..setDartHtmlTemplates("child.dart", ["child.html"])
      ..setDartImports("child.dart", ["grandchild.dart"])
      ..setDartHtmlTemplates("grandchild.dart", ["grandchild.html"]);
    expect(_fileTracker.getHtmlPathsReferencingHtml("child.html"),
        equals(["foo.html"]));
    expect(_fileTracker.getHtmlPathsReferencingHtml("grandchild.html"),
        equals(["child.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlEmpty() {
    expect(_fileTracker.getHtmlPathsReferencingHtml("foo.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlEmptyNoHtml() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", [])
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);
    expect(_fileTracker.getHtmlPathsReferencingHtml("bar.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlEmptyNoImportedDart() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getHtmlPathsReferencingHtml("foo.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlGetSignature() async {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo_test.dart", ["foo.html"])
      ..setDartImports("foo.dart", ["bar.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"]);

    final fooHtmlSignature = ApiSignature()..addInt(1);
    final fooDartElementSignature = '2';
    final fooTestDartElementSignature = '3';
    final barHtmlSignature = ApiSignature()..addInt(4);

    when(_fileHasher.getContentHash("foo.html")).thenReturn(fooHtmlSignature);
    when(_fileHasher.getContentHash("bar.html")).thenReturn(barHtmlSignature);
    when(_fileHasher.getUnitElementSignature("foo.dart"))
        .thenAnswer((_) async => fooDartElementSignature);
    when(_fileHasher.getUnitElementSignature("foo_test.dart"))
        .thenAnswer((_) async => fooTestDartElementSignature);
    when(_options.customEventsHashString).thenReturn('');

    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addBytes(fooHtmlSignature.toByteList())
      ..addString(fooDartElementSignature)
      ..addBytes(barHtmlSignature.toByteList())
      ..addString(fooTestDartElementSignature);

    expect((await _fileTracker.getHtmlSignature("foo.html")).toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_htmlHasHtmlMultipleResults() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html", "foo_b.html"])
      ..setDartImports("foo.dart", ["bar.dart", "baz.dart"])
      ..setDartHtmlTemplates("bar.dart", ["bar.html"])
      ..setDartHtmlTemplates("baz.dart", ["baz.html", "baz_b.html"]);
    expect(_fileTracker.getHtmlPathsReferencingHtml("bar.html"),
        equals(["foo.html", "foo_b.html"]));
    expect(_fileTracker.getHtmlPathsReferencingHtml("baz.html"),
        equals(["foo.html", "foo_b.html"]));
    expect(_fileTracker.getHtmlPathsReferencingHtml("baz_b.html"),
        equals(["foo.html", "foo_b.html"]));
  }

  // ignore: non_constant_identifier_names
  void test_htmlSignature_includesCustomEvents() async {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);

    final fooHtmlSignature = ApiSignature()..addInt(1);
    final fooDartElementSignature = '2';

    when(_fileHasher.getContentHash("foo.html")).thenReturn(fooHtmlSignature);
    when(_fileHasher.getUnitElementSignature("foo.dart"))
        .thenAnswer((_) async => fooDartElementSignature);

    final expectedSignature = ApiSignature()
      ..addInt(FileTracker.salt)
      ..addBytes(fooHtmlSignature.toByteList())
      ..addString(fooDartElementSignature)
      ..addString(r'$customEvents');

    when(_options.customEventsHashString).thenReturn(r'$customEvents');

    expect((await _fileTracker.getHtmlSignature("foo.html")).toHex(),
        equals(expectedSignature.toHex()));
  }

  // ignore: non_constant_identifier_names
  void test_minimallyRehashesHtml() {
    final fooHtmlSignature = ApiSignature()..addInt(1);
    when(_fileHasher.getContentHash("foo.html")).thenReturn(fooHtmlSignature);

    for (var i = 0; i < 3; ++i) {
      _fileTracker.getContentSignature("foo.html");
    }
    verify(_fileHasher.getContentHash("foo.html")).called(1);

    _fileTracker.rehashContents("foo.html");

    for (var i = 0; i < 3; ++i) {
      _fileTracker.getContentSignature("foo.html");
    }
    verify(_fileHasher.getContentHash("foo.html")).called(1);
  }

  // ignore: non_constant_identifier_names
  void test_notReferencedDart() {
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_notReferencedHtml() {
    expect(_fileTracker.getDartPathsReferencingHtml("foo.dart"), equals([]));
  }

  // ignore: non_constant_identifier_names
  void test_templateHasDart() {
    _fileTracker.setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_templatesHaveDart() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo_test.dart", ["foo.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_templatesHaveDartComplex() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html", "foo_b.html"])
      ..setDartHtmlTemplates("foo_test.dart", ["foo.html", "foo_b.html"])
      ..setDartHtmlTemplates("unrelated.dart", ["unrelated.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_b.html"),
        equals(["foo.dart", "foo_test.dart"]));

    _fileTracker.setDartHtmlTemplates("foo_test.dart", ["foo_b.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_b.html"),
        equals(["foo.dart", "foo_test.dart"]));

    _fileTracker.setDartHtmlTemplates("foo_test.dart", ["foo.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_b.html"),
        equals(["foo.dart"]));

    _fileTracker
        .setDartHtmlTemplates("foo_test.dart", ["foo.html", "foo_test.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_b.html"),
        equals(["foo.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_test.html"),
        equals(["foo_test.dart"]));

    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo_b.dart", ["foo_b.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_b.html"),
        equals(["foo_b.dart"]));
    expect(_fileTracker.getDartPathsReferencingHtml("foo_test.html"),
        equals(["foo_test.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_templatesHaveDartRemove() {
    _fileTracker
      ..setDartHtmlTemplates("foo_test.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo_test.dart", []);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart"]));
  }

  // ignore: non_constant_identifier_names
  void test_templatesHaveDartRepeated() {
    _fileTracker
      ..setDartHtmlTemplates("foo.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo_test.dart", ["foo.html"])
      ..setDartHtmlTemplates("foo.dart", ["foo.html"]);
    expect(_fileTracker.getDartPathsReferencingHtml("foo.html"),
        equals(["foo.dart", "foo_test.dart"]));
  }
}

class _AngularOptionsMock extends Mock implements AngularOptions {}

class _FileHasherMock extends Mock implements FileHasher {}
