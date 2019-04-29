# Directive linking

Directive linking is the process of going from a syntactic model to a resolved
model by comparing the syntactic information of directive/component definitions
to the fully resolved element model of a Dart source.

Linking can produce many validation errors that are non-syntactic, such as when
a component refers to a non-existent `templateUrl`. This is not _syntactic_
because the error may go away without changing that `templateUrl` itself, it may
instead be fixed by creating an html file at that specified path.

The main APIs are defined in, or exported by, `link.dart`.

## Relating angular concepts to the Dart element model and vice versa

Linking directives and pipes together requires a means of getting the angular
information of a Dart element. For instance, if `MyComponent` says it uses the
directive `MyDirective`, then the linker needs to take that `ClassElement` for
the class `MyDirective` and load it as a resolved `Directive`. For that reason,
these APIs require a `DirectiveProvider` which can do that.

For performance reasons, that resolved version of `MyDirective` then gets linked
against the `ClassElement` that was originally found in the element model of
`MyComponent`. There is no need for this to request a new element model for
`MyDirective` even if `MyDirective` is defined in another class; the original
element model for `MyComponent` should contain working references for the full
transitive closure of imports and therefore everything required to analyze it.

## Lazy linking

For similar reasons, there are two types of linking; eager and lazy. The lazy
linker merely loads the lazy model with a callback to do eager linking as a load
function.

## After linking

Once a component and its pipe/directive imports are linked, its template is
ready to be resolved.
