# Resolved model

The resolved information in the resolved model will be references to dart
types, or "elements," which are resolved declarations such as `ClassElement`
and `FunctionElement` and such. This information may change when files imported
by the component file, perhaps transitively, change. Therefore, the resolved
model is always created and then quickly thrown away. It cannot be cached.

See the readme for the syntactic model for more details on how this is kept as
performant as possible.

To avoid resolving downstream components unless they are actually used (this is
very common with subdirective lists such as `materialDirectives`), there will
eventually be a third "lazy" model which wraps and implements the resolved
model. Note that upon analyzing some dart file, all the components in that dart
file will have to be eagerly resolved to find all resolution errors, however,
downstream components do not have such a need.

## Relationship to syntactic model

The resolved model also includes necessary offset information for good within
angular templates themselves, but not necessarily offset information required
for validating the definition of those components themselves; those errors will
have been reported during resolution and aren't needed any more. Examples of
this include the directives lists on components.

For that reason, not all resolved model classes extend their syntactic
counter-parts, however, some do such as [ContentChild] and [ContentChildren].

I think ideally, only `syntactic.Component` and `resolved.Component` would not
be related, but there are diamond-type problems there to avoid:
`resolved.BaseClassDirective` should extend both `syntactic.BaseClassDirective`
_and_ `resolved.BaseDirective`. Both of those classes then should extend
`syntactic.BaseDirective`. This could perhaps be fixd with some kind of
`model/common` directory that perhaps has type parameters for
resolved/unresolved lower field types (ie. `T extends common.ContentChild`).
