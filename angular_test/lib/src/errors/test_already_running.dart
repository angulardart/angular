class TestAlreadyRunningError extends Error {
  @override
  String toString() {
    return ''
        'Another instance of an `NgTestFixture` is still executing!\n\n'
        'NgTestBed supports *one* test executing at a time to avoid timing '
        'conflicts or stability issues related to sharing a browser DOM.\n\n'
        'When you are done with a test, make sure to dispose fixtures:\n'
        '  tearDown(() => disposeAnyRunningTest())\n\n'
        'NOTE: `disposeAnyRunningTest` returns a Future that must complete '
        '*before* executing another test - `tearDown` handles this for you '
        'if returned like the example above.';
  }
}
