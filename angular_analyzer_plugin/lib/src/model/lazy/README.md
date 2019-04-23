# Lazy Model

The lazy model is an implementation of the resolved model that contains only
syntactic information, and loads the resolved information through an anonymous
resolution function passed into the constructor.

## Performance

This is important because certain groups of material directives etc are loaded
as a group and then not necessarily all used.

```
  directives: [formDirectives],
```

It also handles what I call the "depth of 1" problem where analyzing a template
requires resolving the directives usable in that template, but it should not
load the children those components themselves.

Previous designs have had many "types" of linking that aim to link these
different depths of components differently, at different times. The lazy
approach is a standard pattern that handles this without having to treat
different depths differently.

It also allows consumers of the plugin as an API in the future to explore the
full tree of directives beyond this "depth of 1" limit, for things like
refactoring and migration tools or metrics. This behavior is not currently
relied upon but it is a plus to the design that it's available.

## Concept

For components and directives, they are matched by a selector before any other
information is used. And for pipes, they are matched by a pipe name.

Ie, given:

```dart
@Component(
  selector: 'my-component',
  ...
) ...

@Directive(
  selector: '[my-directive]',
  ...
) ...

@Pipe('myPipe',
  ...
) ...
```

We can see whether or not the components and directives and pipes are needed in
the following template:

```html
<my-component my-directive></my-component>
{{foo | myPipe}}
```

## Design

Selectors are available in the syntactic model/unlinked summary info, so
its very fast to load. Class elements are also present because thy can be
easily retrieved from the element model by name info in the syntactic model,
and is required for comparing directives/components used in analysis. The class
element itself should also be lazy due to the dart driver design.

Once a selector or pipe name is matched, suddenly almost all of this
information is likely to be used, so it is all loaded by a provided link
function and stored in the component/directive/pipe for reuse.

Functional directives are not lazy loaded because they do not have any
properties worth lazy loading.

Annotated classes (ie base classes with `@Input()` etc) are also not lazy
loaded because they can only be observed in two ways:

- Eagerly analyzing a dart file to find misconfigured `@Input`s etc.
- loading a directive/component which references the base class, in which case
  the full info about that base class is immediately necessary to have.

Therefore only `Directive`s, `Component`s, and `Pipe`s are currently lazy
loaded.
