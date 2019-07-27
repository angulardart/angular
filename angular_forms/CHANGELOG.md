## 2.1.4

*   Maintenance release to support Angular 6.0-alpha+1.

## 2.1.3

*   Maintenance release to support Angular 6.0-alpha.

## 2.1.2

*   Maintenance release to support Angular 5.3.

## 2.1.1

*   Maintenance release to support Angular 5.2.

## 2.1.0

### New Features

*   `PatternValidator` now has a `pattern` input. This allows the `pattern`
    property to be set dynamically. Previously, this could only be specified
    statically at compile time.

## 2.0.0

### New Features

*   Add AbstractControlGroup and AbstractNgForm to allow infrastructure to
    create their own form systems that can be backed by types such as a proto,
    or have different control group logic. Allow NgFormModel and NgControlGroup
    to work with abstract group.

*   `reset` method added to `AbstractControl` and `AbstractControlDirective`.

*   `RequiredValidator` now has a `required` input. This allows the `required`
    property to be toggled at runtime. Previously, this could only be set
    statically at compile time.

*   `Control.invalid` getter added.

*   `Control.markAsPristine` added. This will clear the `dirty` property.

*   Add `ngDisabled` input to all Control directives.

*   Add `MemorizedForm` directive. This is a form that will not remove controls
    if the control is taken out of the view, for example with a [NgIf].

*   Add `disabled` state to `AbstractControl` models. Note: This is not yet
    supported in the template-driven directives.

*   Add `markAsUntouched` method to `AbstractControl`.

*   Add a type annotation, `T`, to `AbstractControl`, which is tied to the type
    of `value`.

*   `ControlGroup` now `extends AbstractControl<Map<String, dynamic>>`.

*   `ControlArray` now `extends AbstractControl<List>`.

### Breaking Changes

*   Use value from AbstractControl for valueChanges event instead of internal
    variable. Allows code to more easily subclass AbstractControl.

*   Remove deprecated `NG_VALUE_ACCESSOR` token. Use `ngValueAccessor` instead.

*   Abstract `updateValue` method added to `AbstractControl`. All subclasses of
    `AbstractControl` will need to implement this method.

*   `NgControlName` will no longer initialize with `null` if a value is
    specified by 'ngModel'.

*   The `touched` property of `Control`s is now propagated to parents /
    children.

*   `NgControlGroup` can no longer be injected directly. It can still be
    injected as a `ControlContainer`.

*   `NgControlName` and `NgFormControl` can no longer be injected directly. They
    can still be injected as a `NgControl`.

*   The following directives are no longer injectable:

    *   `CheckboxControlValueAccessor`
    *   `DefaultValueAccnessor`
    *   `MaxLengthValidator`
    *   `MinLengthValidator`
    *   `NgControlStatus`
    *   `NgSelectOption`
    *   `NumberValueAccessor`
    *   `PatternValidator`
    *   `RadioControlValueAccessor`
    *   `RequiredValidator`

*   Add `ControlValueAccessor.onDisabledChanged()` method. All implementations
    of `ControlValueAccessor` need to add this method.

*   Remove `include` and `exclude` methods from `ControlGroup`. These can be
    replaced with calls to `markAsEnabled` and `markAsDisabled` instead.

    **Before:** `controlGroup.include('foo');`

    **After:** `controlGroup.controls['foo'].markAsEnabled();`

*   `CheckboxControlValueAccessor` now implements `ControlValueAccessor<bool>`
    and `RadioControlValueAccessor` now implements
    `ControlValueAccessor<RadioButtonState>`. Previously, they were both
    `ControlValueAccessor<dynamic>`.

*   Remove `optionals` param from `ControlGroup` constructor. This has been
    replaced by `disabled` state for all `Controls`. See
    https://github.com/dart-lang/angular/issues/1037 for more details.

*   `AbstractControl.find` now only accepts a String. To supply a list, use
    `AbstractControl.findPath` instead. Also, for `find` or `findPath`,
    `ControlArray` index is now calling `int.parse` instead of expecting a raw
    number.

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

*   Changed type of `AbstractControl.statusChanges` from `Stream<dynamic>` to
    `Stream<String>`. This now matches the type for `AbstractControl.status`,
    which as always been a `String`.

*   Allow expressions for maxlength/minlength validators. Breaking change does
    not support string values for maxlength/minlength anymore. `minlength="12"`
    now should be written `[minlength]="12"`

### Bug fixes

*   Add a not selector to ngForm for memorizedForm since memorized_form is now
    in angular_forms. This fixes the DIRECTIVE_EXPORTED_BY_AMBIGIOUS error when
    using: <form #form="ngForm" memorizedForm>

*   Don't throw a null pointer exception in NgFormModel if a directives asks for
    a Control value before the form is initialized.

## 1.0.0

*   Support for angular 4.0.0.

## 0.1.0

*   Initial commit of `angular_forms`.
