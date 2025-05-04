import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/formatters/text_editing_context.dart';

typedef Matcher = bool Function(String char);

class Matchers {
  static Matcher set(Iterable<String> allowed) {
    final set = allowed is Set ? allowed : allowed.toSet();
    return (char) => set.contains(char);
  }

  static Matcher regex(RegExp regex) => (char) => regex.hasMatch(char);
  static Matcher not(Matcher matcher) => (char) => !matcher(char);
  static Matcher or(Matcher a, Matcher b) => (char) => a(char) || b(char);
  static Matcher and(Matcher a, Matcher b) => (char) => a(char) && b(char);
  static bool any(String char) => true;
  static bool none(String char) => false;
  static final Matcher digits = set(List.generate(10, (i) => i.toString()));
}

enum OverflowPolicy {
  /// Prohibit any changes which overflow the mask (restore the previous value)
  cancel,

  /// Truncate the value to the mask length
  truncate,
}

class MaskFormatter extends Formatter {
  final String mask;
  final Map<String, Matcher> maskCharMap;
  final Map<String, String> fallbackMap;
  final OverflowPolicy overflowPolicy;
  final List<Matcher> _positionMatchers;
  final List<Matcher> _rawMatchers;
  bool _initialized = false;

  MaskFormatter({
    required this.mask,
    Map<String, Matcher>? maskCharMap,
    Map<String, String>? fallbackMap,
    this.overflowPolicy = OverflowPolicy.cancel,
  }) : maskCharMap = Map.unmodifiable(maskCharMap ?? {'#': Matchers.digits}),
       fallbackMap = Map.unmodifiable(fallbackMap ?? {}),
       _positionMatchers = List.filled(mask.length, Matchers.none),
       _rawMatchers = List.filled(mask.length, Matchers.none);

  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    // Initialize matchers for each position
    Matcher lastMatcher = Matchers.none;
    for (int i = mask.length - 1; i >= 0; i--) {
      final maskChar = mask[i];
      if (maskCharMap.containsKey(maskChar)) {
        // Variable character - use matcher from map
        final variableMatcher = maskCharMap[maskChar]!;
        _rawMatchers[i] = variableMatcher;
        lastMatcher = variableMatcher;
      } else {
        // Constant character - combine with previous matcher
        final constantMatcher = Matchers.set({maskChar});
        _rawMatchers[i] = constantMatcher;
        lastMatcher = Matchers.or(constantMatcher, lastMatcher);
      }
      _positionMatchers[i] = lastMatcher;
    }
  }

  String _getConstantCharsBetween(int from, int to) {
    final buffer = StringBuffer();
    for (int i = from; i < to; i++) {
      final char = mask[i];
      final fallback = fallbackMap[char];
      if (fallback != null) {
        buffer.write(fallback);
        continue;
      }
      final isVariable = maskCharMap.containsKey(char);
      if (isVariable) {
        break;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatUpdate(TextEditingContext context) {
    initialize();
    final changeType = context.changeType;
    final inserted = changeType.isInsert ?? true;
    int resultLength = 0;
    return streamingEditUpdate(context, (char) {
      if (char == Formatter.eol) {
        // Handle end of line - check if we need to append constant chars
        final constantChars = _getConstantCharsBetween(resultLength, mask.length);
        final isFallback = resultLength < mask.length && maskCharMap.containsKey(mask[resultLength]);
        return ProcessingResult(sequence: inserted ? constantChars : '', cursorShift: isFallback ? 0 : null);
      }

      if (resultLength >= mask.length) {
        if (overflowPolicy == OverflowPolicy.cancel) {
          throw CancelException();
        }
        return ProcessingResult(sequence: '');
      }

      // Reject non-matching characters
      final matcher = _positionMatchers[resultLength];
      if (!matcher(char)) {
        return ProcessingResult(sequence: '');
      }

      // Find first matching position
      final index = _rawMatchers.indexWhere((matcher) => matcher(char), resultLength);
      final constantChars = _getConstantCharsBetween(resultLength, index);
      resultLength = index + 1;
      return ProcessingResult(sequence: constantChars + char);
    });
  }
}
