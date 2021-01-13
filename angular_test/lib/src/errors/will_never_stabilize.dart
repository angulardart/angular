/// Operation to stabilize the DOM during a test failed.
class WillNeverStabilizeError extends Error {
  final int threshold;

  WillNeverStabilizeError(this.threshold);

  @override
  String toString() => 'Failed to stabilize after $threshold attempts';
}
