## 2.0.0-alpha

**NOTE**: This used to be `1.0.1-alpha`, but has changed to be `2.0.0-alpha` due
to the fact that there are breaking changes in the previous dev releases. Future
development releases are moving to `2.x.x`, and a `1.0.1` will never be
released.

### Breaking changes

*   `AbstractControl.find` now only accepts a String. To supply a list, use
    `AbstractControl.findPath` instead. Also, for `find` or `findPath`,
    `ControlArray` index is now calling `int.parse` instead of expecting a raw
    number.

## 1.0.1-alpha+7

### Breaking changes

*   The following directives are no longer injectable:

    *   `NgControlStatus`
    *   `RequiredValidator`
    *   `MinLengthValidator`
    *   `MaxLengthValidator`
    *   `PatternValidator`

*   Properly typed the generic parameter on subclasses of
    `AbstractControlDirective`. Now, `NgControl.control` will return a
    `Control`, and `ControlContainer.control` will return a `ControlGroup`.
    There may be some unnecessary casts that can now be cleaned up.

*   `FormBuilder` instance methods `group`, `control`, and `array` have been
    removed. For `FormBuilder.control`, just call `new Control(value,
    validator)` directly. For `FormBuilder.group` and `FormBuilder.array`, use
    the static methods `FormBuilder.controlGroup` and
    `FormBuilder.controlArray`, respectively. `FormBuilder` is no longer
    `Injectable`.

## 1.0.1-alpha+6

### New features

*   Add `markAsUntouched` method to `AbstractControl`.
*   Add a type annotation, `T`, to `AbstractControl`, which is tied to the type
    of `value`.
*   `ControlGroup` now `extends AbstractControl<Map<String, dynamic>>`.
*   `ControlArray` now `extends AbstractControl<List>`.

### Breaking Changes

*   Changed type of `AbstractControl.statusChanges` from `Stream<dynamic>` to
    `Stream<String>`. This now matches the type for `AbstractControl.status`,
    which as always been a `String`.

### Deprecations

*   `FormBuilder` instance methods `group`, `control`, and `array` are now
    deprecated. For `FormBuilder.control`, just call `new Control(value,
    validator)` directly. For `FormBuilder.group` and `FormBuilder.array`, use
    the static methods `FormBuilder.controlGroup` and `FormBuilder.controlArray`
    respectively. In a future release, `FormBuilder` will not not be
    `Injectable`.

## 1.0.1-alpha+5

_Maintenance release, to support the latest package:angular alpha._

## 1.0.1-alpha+4

_Maintenance release, to support the latest package:angular alpha._

## 1.0.1-alpha+3

*   Some documentation updates.
*   Dartium is no longer supported.

## 1.0.1-alpha+2

_Maintenance release, to support the latest package:angular alpha._

## 1.0.1-alpha+1

*   Use the new generic function syntax, stop using `package:func`.
*   Don't throw a null pointer exception in NgFormModel if a directives asks for
    a Control value before the form is initialized.

## 1.0.1-alpha

*   Support breaking changes in angular 5.0.0-alpha
*   Allow expressions for maxlength/minlength validators. Breaking change does
    not support string values for maxlength/minlength anymore. `minlength="12"`
    now should be written `[minlength]="12"`

## 1.0.0

*   Support for angular 4.0.0.

## 0.1.0

*   Initial commit of `angular_forms`.
