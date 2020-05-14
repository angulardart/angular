bool isPrimitive(Object obj) =>
    obj is num || obj is bool || obj == null || obj is String;
