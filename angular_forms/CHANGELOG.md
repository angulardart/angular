## 1.0.1-alpha+6

### New features

-   Add `markAsUntouched` method to `AbstractControl`.
-   Add a type annotation, `T`, to `AbstractControl`, which is tied to the type
    of `value`.
-   `ControlGroup` now `extends AbstractControl<Map<String, dynamic>>`.
-   `ControlArray` now `extends AbstractControl<List>`.

### Breaking Changes

-   Changed type of `AbstractControl.statusChanges` from `Stream<dynamic>` to
    `Stream<String>`. This now matches the type for `AbstractControl.status`,
    which as always been a `String`.

### Deprecations

-   `FormBuilder` instance methods `group`, `control`, and `array` are now
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

-   Some documentation updates.
-   Dartium is no longer supported.

## 1.0.1-alpha+2

_Maintenance release, to support the latest package:angular alpha._

## 1.0.1-alpha+1

-   Use the new generic function syntax, stop using `package:func`.
-   Don't throw a null pointer exception in NgFormModel if a directives asks for
    a Control value before the form is initialized.

## 1.0.1-alpha

-   Support breaking changes in angular 5.0.0-alpha
-   Allow expressions for maxlength/minlength validators. Breaking change does
    not support string values for maxlength/minlength anymore. `minlength="12"`
    now should be written `[minlength]="12"`

## 1.0.0

-   Support for angular 4.0.0.

## 0.1.0

-   Initial commit of `angular_forms`.
