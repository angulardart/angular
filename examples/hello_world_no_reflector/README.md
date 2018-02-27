An example of a simple "Hello World", using an experimental bootstrap process.

This is nearly identical to `hello_world`, but with improved tree-shaking.

## Running locally

To debug locally with DDC:

```bash
$ pub get
$ pub run build_runner serve
```

To debug locally with Dart2JS, unminified:

```bash
$ pub get
$ pub run build_runner serve --config=debug 
```

To debug locally with Dart2JS, minified:

```bash
$ pub get
$ pub run build_runner serve --config=release 
```

## Building a binary

```bash
$ pub get
$ pun run build_runner build --config=release -o build
```
