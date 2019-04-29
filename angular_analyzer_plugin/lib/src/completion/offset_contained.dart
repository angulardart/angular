bool offsetContained(int offset, int start, int length) =>
    start <= offset && start + length >= offset;
