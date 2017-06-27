// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Stream<String> standardIoToLines(Stream<List<int>> source) =>
    source.transform(SYSTEM_ENCODING.decoder).transform(const LineSplitter());
