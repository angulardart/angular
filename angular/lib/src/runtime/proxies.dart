/// Used to implement collection literals and pure pipes.

/// Represents an empty list literal in a template (`[]`).
///
/// Type is [Null] in order to implement all expected types of List.
const emptyListLiteral = <Null>[];

T Function(S0) pureProxy1<T, S0>(T Function(S0) fn) {
  T result;
  var first = true;
  S0 v0;
  return (S0 p0) {
    if (first || !identical(v0, p0)) {
      first = false;
      v0 = p0;
      result = fn(p0);
    }
    return result;
  };
}

T Function(S0, S1) pureProxy2<T, S0, S1>(T Function(S0, S1) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  return (S0 p0, S1 p1) {
    if (first || !identical(v0, p0) || !identical(v1, p1)) {
      first = false;
      v0 = p0;
      v1 = p1;
      result = fn(p0, p1);
    }
    return result;
  };
}

T Function(S0, S1, S2) pureProxy3<T, S0, S1, S2>(T Function(S0, S1, S2) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  return (S0 p0, S1 p1, S2 p2) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      result = fn(p0, p1, p2);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3) pureProxy4<T, S0, S1, S2, S3>(
    T Function(S0, S1, S2, S3) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  return (S0 p0, S1 p1, S2 p2, S3 p3) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      result = fn(p0, p1, p2, p3);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4) pureProxy5<T, S0, S1, S2, S3, S4>(
    T Function(S0, S1, S2, S3, S4) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      result = fn(p0, p1, p2, p3, p4);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4, S5) pureProxy6<T, S0, S1, S2, S3, S4, S5>(
    T Function(S0, S1, S2, S3, S4, S5) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      result = fn(p0, p1, p2, p3, p4, p5);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4, S5, S6)
    pureProxy7<T, S0, S1, S2, S3, S4, S5, S6>(
        T Function(S0, S1, S2, S3, S4, S5, S6) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      result = fn(p0, p1, p2, p3, p4, p5, p6);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4, S5, S6, S7)
    pureProxy8<T, S0, S1, S2, S3, S4, S5, S6, S7>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6, S7 p7) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8)
    pureProxy9<T, S0, S1, S2, S3, S4, S5, S6, S7, S8>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  S8 v8;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6, S7 p7, S8 p8) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7) ||
        !identical(v8, p8)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      v8 = p8;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7, p8);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8, S9)
    pureProxy10<T, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8, S9) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  S8 v8;
  S9 v9;
  return (
    S0 p0,
    S1 p1,
    S2 p2,
    S3 p3,
    S4 p4,
    S5 p5,
    S6 p6,
    S7 p7,
    S8 p8,
    S9 p9,
  ) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7) ||
        !identical(v8, p8) ||
        !identical(v9, p9)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      v8 = p8;
      v9 = p9;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9);
    }
    return result;
  };
}
