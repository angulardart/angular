@TestOn('browser')
library angular2.test.compiler.view_resolver_test;

import "package:angular2/src/compiler/view_resolver.dart" show ViewResolver;
import "package:angular2/src/core/metadata.dart" show Component;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

class SomeDir {}

class SomePipe {}

@Component(
    selector: "sample",
    template: "some template",
    directives: const [SomeDir],
    pipes: const [SomePipe],
    styles: const ["some styles"])
class ComponentWithView {}

@Component(
    selector: "sample",
    template: "some template",
    directives: const [SomeDir],
    pipes: const [SomePipe],
    styles: const ["some styles"])
class ComponentWithTemplate {}

@Component(selector: "sample", template: "some template")
class ComponentWithViewTemplate {}

@Component(
    selector: "sample",
    templateUrl: "some template url",
    template: "some template")
class ComponentWithViewTemplateUrl {}

@Component(selector: "sample")
class ComponentWithoutView {}

class SimpleClass {}

void main() {
  group("ViewResolver", () {
    ViewResolver resolver;
    setUp(() async {
      resolver = new ViewResolver();
      inject([], () {});
    });
    test("should read out the View metadata from the Component metadata", () {
      var viewMetadata = resolver.resolve(ComponentWithTemplate);
      expect(viewMetadata.template, "some template");
      expect(viewMetadata.directives, [SomeDir]);
      expect(viewMetadata.pipes, [SomePipe]);
      expect(viewMetadata.styles, ["some styles"]);
    });
    test(
        "should throw when Component has no View decorator and no template is set",
        () {
      expect(
          () => resolver.resolve(ComponentWithoutView),
          throwsWith("Component 'ComponentWithoutView' must have either "
              "'template' or 'templateUrl' set"));
    });
    test(
        'should throw when simple class has no View decorator and no '
        'template is set', () {
      expect(
          () => resolver.resolve(SimpleClass),
          throwsWith('Could not compile \'SimpleClass\' because it is '
              'not a component.'));
    });
  });
}
