# Change Detection FAQ


Change detection is the workhorse that drives Angular applications. As such, it
is important to understand its workings to write performant apps. Being the
main factor in an AngularDart app's performance, we receive several common
questions about change detection.

A basic understanding of how change detection functions in an Angular app
will help clear up common misconceptions and fill gaps in knowledge.

## Overview of change detection

The default change detection strategy in Angular is quite simple. Angular
runs a change detection loop throughout the lifetime of your app.
On each iteration of the loop, Angular performs change detection of the root
element of the component tree. Once every expression in the root element has
been checked, change detection is recursively called for all children of the
element, all the way down to the leaf elements.

### Change detection of a single component

So, we've seen that Angular recursively change detects each component and
directive in the tree, but how is each individual component change detected?

For each component, the Angular Compiler generates a method that detects
changes for each expression in its template. If the expression has changed
since the last check, it will execute code to update the value the expression
is bound to. It's important to remember that components don't change detect
their own inputs, they run change detection on the expressions in their own
template, and will - for example - set an input on a child component only if
the expression it's bound to has changed.

For example, given a component with the following template:

```html
<div>{{message}}</div>
<child-component [input]="someExpression"></child-component>
```

The Angular Compiler will generate a change detection method for this
component that checks two things: `message` and `someExpression` on every
change detection loop.

**IMPORTANT NOTE**: An expression has "changed" if its value in this iteration
is not `identical` to its previous value. This means that it's possible for an
expression to change, and not have that change reflected in Angular. This is
common with collection types such as `List` because when you change the
elements of the list, it is still `identical` because it is the same `List`
instance. If you want to reflect a change in a collection type, you must pass
a new collection instance.

## Frequently Asked Questions

### What does "Expression has changed after it was checked" mean?

As we have seen, every expression in every template is checked in each change
detection loop, and code is run to update bindings only if the expression has
changed since the last change detection loop. Clearly, this can be expensive
for expressions that change on _every_ change detection loop.

To help users guard against this, Angular does additional verification when
an app is built in debug mode. In debug mode, Angular will run change
detection on every component and directive **twice**, and if any expressions
have changed between the first and second run, this is an indication of
misbehaving code. In this case, Angular will throw an exception saying
"Expression has changed after it was checked."

Often, in this case, the expression is a getter that returns a new instance
every time it is accessed. This is very bad behavior for Angular and will
cause this exception to throw. Always make sure that if an expression hasn't
changed it's value, that it stays `identical` to the previous value.

### How does change detection work for Lists and Maps?

Change detection for maps works just like any other expression. Angular will
only detect a change if the `identity` of the List or Map has changed. _Angular
does not check the contents of Lists or Maps_. This means, if you are using a
component that takes a List or a Map as input, and you want to ensure that
change detection fires for that input after you've made a change, _you must
pass a new List or Map instance_.

#### Why don't I need to pass a new List instance to `NgFor`?

`NgFor` and its friends `NgStyle` and `NgClass` are _special_. They implement
`DoCheck` allowing them to perform extra manual work on each change detection
cycle. These directives perform change detection on the _elements of the
collection_ because they have implemented extra logic to do so. So, even if
the input has not changed its `identity` changes in its elements will be
reflected in these directives. But it is important to remember this is not
the case in general.

### Does Angular check `final` fields?

No. Angular has implemented an optimization allowing the compiler to know that
`final` fields _never_ need to be change detected. There is a somewhat common
misconception that change detection for `final` fields is only skipped if the
type of the field is a primitive type (`String`, `bool`, `int`, etc.) but this
optimization applies to all final fields, _regardless of type_.

### Can Angular skip change detection for Immutable types?

No. For example, let's look at the following component:

```dart
@Component(
  selector: 'my-component',
  template: '<child-component [input]="immutableList"></child-component>'
)
class MyComponent {
  ImmutableList immutableList = const ImmutableList();
}
```

It would be unsafe to skip change detection for `immutableList`, even if we
know statically that it's type is `ImmutableList`. This is because
`immutableList` is not `final`. Suppose `MyComponent` had another method
that changed `immutableList`

```dart
class MyComponent {
  // ...

  void foo() {
    immutableList = ImmutableList();
  }
}
```

As we can see, `immutableList` has clearly changed! Angular's change detection
must respond to this change to work correctly.
