// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:sass_builder/sass_builder.dart' as sass;

Builder scssBuilder(BuilderOptions options) =>
    // Internally, we do not use this file, so it causes a lint.
    // ... just ignore it, we won't change this file often.
    //
    // ignore: strong_mode_invalid_cast_new_expr, new_with_non_type
    new sass.SassBuilder(outputExtension: '.scss.css');
