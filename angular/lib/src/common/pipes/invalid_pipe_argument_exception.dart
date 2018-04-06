class InvalidPipeArgumentException extends FormatException {
  InvalidPipeArgumentException(Type type, Object value)
      : super("Invalid argument '$value' for pipe '$type'");
}
