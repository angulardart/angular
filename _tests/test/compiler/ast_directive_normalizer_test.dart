@TestOn('vm')
import 'dart:async';
import 'package:angular/core.dart';
import 'package:angular/src/compiler/ast_directive_normalizer.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  CompileDirectiveMetadata metadata;
  AstDirectiveNormalizer normalizer;
  FakeAssetReader reader;

  test('should do nothing for an @Directive', () async {
    reader = const FakeAssetReader();
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Directive,
    );

    expect(
      await normalizer.normalizeDirective(metadata),
      same(metadata),
      reason: 'Should be a no-op if not a Component',
    );
  });

  test('should warn when template: points to a file URL', () async {
    final logs = <String>[];
    final logger = Logger('test');
    final sub = logger.onRecord.listen((r) => logs.add('$r'));
    addTearDown(sub.cancel);
    reader = FakeAssetReader({
      'package:a/a.dart': '',
      'package:a/a.html': '',
    });
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(
        moduleUrl: 'asset:a/lib/a.dart',
      ),
      template: CompileTemplateMetadata(
        template: 'a.html',
      ),
    );
    await scopeLogAsync(() => normalizer.normalizeDirective(metadata), logger);
    expect(logs, contains(contains('did you mean "templateUrl"')));
  });

  test('should warn when styles: points to a file URL', () async {
    final logs = <String>[];
    final logger = Logger('test');
    final sub = logger.onRecord.listen((r) => logs.add('$r'));
    addTearDown(sub.cancel);
    reader = FakeAssetReader({
      'package:a/a.dart': '',
      'package:a/a.css': '',
    });
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(
        moduleUrl: 'asset:a/lib/a.dart',
      ),
      template: CompileTemplateMetadata(
        styles: [
          'a.css',
        ],
        template: '',
      ),
    );
    await scopeLogAsync(() => normalizer.normalizeDirective(metadata), logger);
    expect(logs, contains(contains('did you mean "styleUrls"')));
  });

  test('should throw when neither a template or templateUrl set', () async {
    reader = FakeAssetReader();
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(
        moduleUrl: 'asset:a/lib/a.dart',
      ),
      template: CompileTemplateMetadata(),
    );
    expect(normalizer.normalizeDirective(metadata), throwsBuildError);
  });

  test('should read all <ng-content> tags', () async {
    reader = FakeAssetReader();
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(moduleUrl: 'asset:a/lib/a.dart'),
      template: CompileTemplateMetadata(
        template: r'''
          <ng-content></ng-content>
          <ng-content select=".left"></ng-content>
          <ng-content select=".right"></ng-content>
        ''',
      ),
    );
    metadata = await normalizer.normalizeDirective(metadata);
    expect(metadata.template.ngContentSelectors, [
      '*',
      '.left',
      '.right',
    ]);
  });

  test('should read all external stylesheets', () async {
    reader = FakeAssetReader({
      'package:a/1.css': '',
      'package:a/2.css': '',
      'package:a/3.css': '',
      'package:a/4.css': '',
    });
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(moduleUrl: 'package:a/a.dart'),
      template: CompileTemplateMetadata(
        template: r'''
          <link href="3.css" rel="stylesheet" />
          <style>
            @import url('4.css');
          </style>
        ''',
        styleUrls: [
          '1.css',
          '2.css',
        ],
      ),
    );
    metadata = await normalizer.normalizeDirective(metadata);
    expect(
      metadata.template.styleUrls,
      orderedEquals([
        'package:a/1.css',
        'package:a/2.css',
      ]),
    );
  });

  test('should turn off view encapsulation if there are no styles', () async {
    reader = FakeAssetReader();
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(moduleUrl: 'package:a/a.dart'),
      template: CompileTemplateMetadata(
        template: '',
        encapsulation: ViewEncapsulation.Emulated,
      ),
    );
    metadata = await normalizer.normalizeDirective(metadata);
    expect(metadata.template.encapsulation, ViewEncapsulation.None);
  });

  test('should resolve inline stylesheets', () async {
    reader = FakeAssetReader({
      'package:a/1.css': ':host { color: red }',
      'package:a/2.css': ':host { width: 10px; }',
      'package:a/3.css': ':host { height: 10px; }',
      'package:a/4.css': ':host { background: #FFF; }',
    });
    normalizer = AstDirectiveNormalizer(reader);
    metadata = CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: CompileTypeMetadata(moduleUrl: 'package:a/a.dart'),
      template: CompileTemplateMetadata(
        template: r'''
          <link href="3.css" rel="stylesheet" />
          <style>
            :host { padding: 10px; }
          </style>
        ''',
        styleUrls: [
          '1.css',
          '2.css',
        ],
        styles: [
          ':host { margin: 10px; }',
        ],
      ),
    );
    metadata = await normalizer.normalizeDirective(metadata);
    expect(metadata.template.encapsulation, ViewEncapsulation.Emulated);
    expect(
      metadata.template.styles,
      [
        contains(':host { margin: 10px; }'),
      ],
      reason: 'Only one inline style should have been processed',
    );
  });
}

class FakeAssetReader extends NgAssetReader {
  final Map<String, String> _cache;

  const FakeAssetReader([this._cache = const {}]);

  @override
  Future<bool> canRead(String url) => Future.value(_cache.containsKey(url));

  @override
  Future<String> readText(String url) => Future.value(_cache[url]);
}

final throwsBuildError = throwsA(const TypeMatcher<BuildError>());
