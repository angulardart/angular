library angular2.test.compiler.test_bindings;

import "package:angular/src/compiler/schema/element_schema_registry.dart"
    show ElementSchemaRegistry;
import "package:angular/src/compiler/xhr.dart" show XHR;
import "package:angular/src/compiler/xhr_mock.dart" show MockXHR;
import "package:angular/src/core/di.dart" show Provider;
import "package:angular/src/core/url_resolver.dart"
    show UrlResolver, createUrlResolverWithoutPackagePrefix;

import "schema_registry_mock.dart" show MockSchemaRegistry;

const List<Provider> TEST_PROVIDERS = const <Provider>[
  const Provider(ElementSchemaRegistry, useFactory: createRegistry),
  const Provider(XHR, useClass: MockXHR),
  const Provider(UrlResolver, useFactory: createUrlResolverWithoutPackagePrefix)
];

MockSchemaRegistry createRegistry() => new MockSchemaRegistry({}, {});
