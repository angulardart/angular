library angular2.test.compiler.compile_metadata_test;

import "package:angular2/src/compiler/compile_metadata.dart";
import "package:angular2/src/core/change_detection.dart"
    show ChangeDetectionStrategy;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:test/test.dart';

main() {
  group("CompileMetadata", () {
    CompileTypeMetadata fullTypeMeta;
    CompileTemplateMetadata fullTemplateMeta;
    CompileDirectiveMetadata fullDirectiveMeta;
    setUp(() {
      var diDep = new CompileDiDependencyMetadata(
          isAttribute: true,
          isSelf: true,
          isHost: true,
          isSkipSelf: true,
          isOptional: true,
          token: new CompileTokenMetadata(value: "someToken"),
          query: new CompileQueryMetadata(
              selectors: [new CompileTokenMetadata(value: "one")],
              descendants: true,
              first: true,
              propertyName: "one"),
          viewQuery: new CompileQueryMetadata(
              selectors: [new CompileTokenMetadata(value: "one")],
              descendants: true,
              first: true,
              propertyName: "one"));
      fullTypeMeta = new CompileTypeMetadata(
          name: "SomeType",
          moduleUrl: "someUrl",
          isHost: true,
          diDeps: [diDep]);
      fullTemplateMeta = new CompileTemplateMetadata(
          encapsulation: ViewEncapsulation.Emulated,
          template: "<a></a>",
          templateUrl: "someTemplateUrl",
          styles: ["someStyle"],
          styleUrls: ["someStyleUrl"],
          ngContentSelectors: ["*"]);
      fullDirectiveMeta = CompileDirectiveMetadata.create(
          selector: "someSelector",
          isComponent: true,
          type: fullTypeMeta,
          template: fullTemplateMeta,
          changeDetection: ChangeDetectionStrategy.Default,
          inputs: [
            "someProp"
          ],
          outputs: [
            "someEvent"
          ],
          host: {
            "(event1)": "handler1",
            "[prop1]": "expr1",
            "attr1": "attrValue2"
          },
          lifecycleHooks: [
            LifecycleHooks.OnChanges
          ],
          providers: [
            new CompileProviderMetadata(
                token: new CompileTokenMetadata(value: "token"),
                multi: true,
                useClass: fullTypeMeta,
                useExisting: new CompileTokenMetadata(
                    identifier: new CompileIdentifierMetadata(name: "someName"),
                    identifierIsInstance: true),
                useFactory: new CompileFactoryMetadata(
                    name: "someName", diDeps: [diDep]),
                useValue: "someValue")
          ],
          viewProviders: [
            new CompileProviderMetadata(
                token: new CompileTokenMetadata(value: "token"),
                useClass: fullTypeMeta,
                useExisting: new CompileTokenMetadata(
                    identifier:
                        new CompileIdentifierMetadata(name: "someName")),
                useFactory: new CompileFactoryMetadata(
                    name: "someName", diDeps: [diDep]),
                useValue: "someValue")
          ],
          queries: [
            new CompileQueryMetadata(
                selectors: [new CompileTokenMetadata(value: "selector")],
                descendants: true,
                first: false,
                propertyName: "prop",
                read: new CompileTokenMetadata(value: "readToken"))
          ],
          viewQueries: [
            new CompileQueryMetadata(
                selectors: [new CompileTokenMetadata(value: "selector")],
                descendants: true,
                first: false,
                propertyName: "prop",
                read: new CompileTokenMetadata(value: "readToken"))
          ]);
    });
    group("CompileIdentifierMetadata", () {
      test("should serialize with full data", () {
        var full = new CompileIdentifierMetadata(
            name: "name",
            moduleUrl: "module",
            value: [
              "one",
              ["two"]
            ]);
        expect(CompileIdentifierMetadata.fromJson(full.toJson()).toJson(),
            full.toJson());
      });
      test("should serialize with no data", () {
        var empty = new CompileIdentifierMetadata();
        expect(CompileIdentifierMetadata.fromJson(empty.toJson()).toJson(),
            empty.toJson());
      });
    });
    group("DirectiveMetadata", () {
      test("should serialize with full data", () {
        expect(
            CompileDirectiveMetadata
                .fromJson(fullDirectiveMeta.toJson())
                .toJson(),
            fullDirectiveMeta.toJson());
      });
      test("should serialize with no data", () {
        var empty = CompileDirectiveMetadata.create();
        expect(CompileDirectiveMetadata.fromJson(empty.toJson()).toJson(),
            empty.toJson());
      });
    });
    group("TypeMetadata", () {
      test("should serialize with full data", () {
        expect(CompileTypeMetadata.fromJson(fullTypeMeta.toJson()).toJson(),
            fullTypeMeta.toJson());
      });
      test("should serialize with no data", () {
        var empty = new CompileTypeMetadata();
        expect(CompileTypeMetadata.fromJson(empty.toJson()).toJson(),
            empty.toJson());
      });
    });
    group("TemplateMetadata", () {
      test("should use ViewEncapsulation.Emulated by default", () {
        expect(new CompileTemplateMetadata(encapsulation: null).encapsulation,
            ViewEncapsulation.Emulated);
      });
      test("should serialize with full data", () {
        expect(
            CompileTemplateMetadata
                .fromJson(fullTemplateMeta.toJson())
                .toJson(),
            fullTemplateMeta.toJson());
      });
      test("should serialize with no data", () {
        var empty = new CompileTemplateMetadata();
        expect(CompileTemplateMetadata.fromJson(empty.toJson()).toJson(),
            empty.toJson());
      });
    });
  });
}
