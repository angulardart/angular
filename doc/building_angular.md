# Building Angular

AngularDart uses `package:build` as a build system for compiling Angular
components.

1.  Edit your package's **pubspec.yaml** file, adding dev dependencies on
    **build_runner** and **build_web_compilers**:

    ```yaml
    ...
    environment:
      sdk: '>=2.0.0-dev <2.0.0'
    ...
    dev_dependencies:
      build_runner: ^0.7.0
      build_web_compilers: ^0.2.0
    ```

2.  Get package dependencies:

    ```sh
    pub get
    ```

3.  Start the server:

    ```sh
    pub run build_runner serve
    ```

While the `serve` command runs, every change you save triggers a rebuild.

For more details, see the [Getting Started guide][getting_started] from
`build_runner`.

[getting_started]: https://github.com/dart-lang/build/blob/master/docs/getting_started.md
