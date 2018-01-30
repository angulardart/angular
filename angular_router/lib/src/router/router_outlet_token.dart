// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular/angular.dart';

import '../directives/router_outlet_directive.dart';

/// **INTERNAL ONLY**: An injected token to access [RouterOutlet]s.
///
/// The [Router] will inject a new token with each [Component] created. The
/// angular component will initialize and it's [RouterOutlet] will also
/// initialize. The RouterOutlet's constructor will then attach itself to the
/// token, enabling the Router to have a point to the RouterOutlet.
class RouterOutletToken {
  RouterOutlet routerOutlet;
}
