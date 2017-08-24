// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Additional API to be used when migrating existing code to `angular_test`.
///
/// It is **highly recommended** not to use this and only stick to
/// `angular_test.dart` for any new code or for new users of this package. APIs
/// may change at _any time_ without adhering strictly to sem-ver.
@experimental
library angular_test.compatibility;

import 'package:meta/meta.dart';

export 'src/bootstrap.dart' show bootstrapForTest, createTestInjector;
export 'src/frontend/bed.dart' show createDynamicFixture, createDynamicTestBed;
export 'src/frontend/fixture.dart' show injectFromFixture;
