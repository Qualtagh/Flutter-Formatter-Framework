/// A result of [streamingEditUpdate] step
class StreamStepResult {
  /// A sequence to insert instead of the original character.
  /// Examples:
  /// - full input - '$', input char - '$', output sequence - '$0', full output - '$0'
  /// - full input - '2358', input char - '5', output sequence - '-5', full output - '23-58'
  final String sequence;

  /// A shift of the cursor position. By default, it's a length of the sequence.
  /// Example: full input - '10.', input char - '.', output sequence - '.00', full output - '10.00'
  /// - cursor shift - 3 (default), position - '10.00|'
  /// - cursor shift - 2, position - '10.0|0'
  /// - cursor shift - 1, position - '10.|00'
  /// - cursor shift - 0, position - '10|.00'
  /// Note that it's only applied in case of insertion. Deletion of characters ignores this value.
  final int cursorShift;

  StreamStepResult({required this.sequence, int? cursorShift}) : cursorShift = cursorShift ?? sequence.length;
}
