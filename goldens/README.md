A WIP destination for golden file testing.

See b/147830720.

TIP: Need to update all of the tests quickly? Use:

```bash
$ third_party/dart_src/angular/goldens/update_all.sh
```

Currently when adding a new `a.dart` file, you must add a sibling
`a.template.dart.golden` and `a.js.golden` file, otherwise the resulting
`golden_test` macro will fail saying those files are not found.
