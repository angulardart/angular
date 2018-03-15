import 'dart:async';

@TestOn('vm')
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
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
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
    final logger = new Logger('test');
    final sub = logger.onRecord.listen((r) => logs.add('$r'));
    addTearDown(sub.cancel);
    reader = new FakeAssetReader({
      'package:a/a.dart': '',
      'package:a/a.html': '',
    });
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: new CompileTypeMetadata(
        moduleUrl: 'asset:a/lib/a.dart',
      ),
      template: new CompileTemplateMetadata(
        template: 'a.html',
      ),
    );
    await scopeLogAsync(() => normalizer.normalizeDirective(metadata), logger);
    expect(logs, contains(contains('did you mean "templateUrl"')));
  });

  test('should throw when neither a template or templateUrl set', () async {
    reader = new FakeAssetReader();
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: new CompileTypeMetadata(
        moduleUrl: 'asset:a/lib/a.dart',
      ),
      template: new CompileTemplateMetadata(),
    );
    expect(normalizer.normalizeDirective(metadata), throwsBuildError);
  });

  test('should read all <ng-content> tags', () async {
    reader = new FakeAssetReader();
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: new CompileTypeMetadata(moduleUrl: 'asset:a/lib/a.dart'),
      template: new CompileTemplateMetadata(
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
    reader = new FakeAssetReader({
      'package:a/1.css': '',
      'package:a/2.css': '',
      'package:a/3.css': '',
      'package:a/4.css': '',
    });
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: new CompileTypeMetadata(moduleUrl: 'package:a/a.dart'),
      template: new CompileTemplateMetadata(
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
    expect(metadata.template.styleUrls, unorderedEquals([
      'package:a/1.css',
      'package:a/2.css',
      'package:a/3.css',

      // @import URLs are not resolved at build-time.
      'packages/a/4.css',
    ]));
  });

  test('should turn off view encapsulation if there are no styles', () async {
    reader = new FakeAssetReader();
    normalizer = new AstDirectiveNormalizer(reader);
    metadata = new CompileDirectiveMetadata(
      metadataType: CompileDirectiveMetadataType.Component,
      type: new CompileTypeMetadata(moduleUrl: 'package:a/a.dart'),
      template: new CompileTemplateMetadata(
        template: '',
        encapsulation: ViewEncapsulation.Emulated,
      ),
    );
    metadata = await normalizer.normalizeDirective(metadata);
    expect(metadata.template.encapsulation, ViewEncapsulation.None);
  });
}

class FakeAssetReader extends NgAssetReader {
  final Map<String, String> _cache;

  const FakeAssetReader([this._cache = const {}]);

  @override
  Future<bool> canRead(String url) => new Future.value(_cache.containsKey(url));

  @override
  Future<String> readText(String url) => new Future.value(_cache[url]);
}

final throwsBuildError = throwsA(const isInstanceOf<BuildError>());
