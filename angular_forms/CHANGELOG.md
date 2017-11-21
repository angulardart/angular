## 1.0.1-alpha+1

-   Use the new generic function syntax, stop using `package:func`.
-   Don't throw a null pointer exception in NgFormModel if a directives asks for
    a Control value before the form is initialized.

## 1.0.1-alpha

-   Support breaking changes in angular 5.0.0-alpha
-   Allow expressions for maxlength/minlength validators. Breaking change does
    not support string values for maxlength/minlength anymore.
    `minlength="12"` now should be written `[minlength]="12"`

## 1.0.0
-   Support for angular 4.0.0.

## 0.1.0

-   Initial commit of `angular_forms`.
