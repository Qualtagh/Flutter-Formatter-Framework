import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/cancel_exception.dart';
import 'package:flutter_formatter_framework/types/matchers.dart';
import 'package:flutter_formatter_framework/types/stream_step_result.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';
import 'package:flutter_formatter_framework/util/streaming_edit_update.dart';

enum OverflowPolicy {
  /// Prohibit any changes which overflow the mask (restore the previous value).
  /// Example: mask = '####', cursor at 2, value = '12|34', enter '0' => '12|34' (no changes)
  cancel,

  /// Truncate the value to the mask length.
  /// Example: mask = '####', cursor at 2, value = '12|34', enter '0' => '120|3'
  truncate,
}

enum CompletionPolicy {
  /// Stop exactly at the end of input.
  /// Example: mask = '##-##', value = '1', enter '2' => '12' (no dash at the end)
  lazy,

  /// At the end of input, add all constant and fallback characters from the mask.
  /// Example: mask = '##-##', value = '1', enter '2' => '12-' (with dash at the end)
  eager,

  /// Add only pure constant characters. Stop before fallback characters.
  /// If [fallbackMap] is empty, this is the same as [eager].
  /// Example: mask = '##.@@', value = '1', enter '2', a fallback for '@' is '0' => '12.' (dot is added, but 0 is not)
  lazyIfFallback,

  /// Add only fallback characters. Stop before constant characters.
  /// If [fallbackMap] is empty, this is the same as [lazy].
  /// Example: mask = '##@.@@', value = '1', enter '2', a fallback for '@' is '0' => '120' (0 is added, but dot is not)
  eagerIfFallback,
}

class MaskFormatter extends Formatter {
  final String mask;
  final Map<String, Matcher> maskCharMap;
  final Map<String, String> fallbackMap;
  final OverflowPolicy overflowPolicy;
  final CompletionPolicy completionPolicy;
  final List<Matcher> _positionMatchers;
  final List<Matcher> _rawMatchers;
  bool _initialized = false;

  MaskFormatter({
    required this.mask,
    Map<String, Matcher>? maskCharMap,
    Map<String, String>? fallbackMap,
    this.overflowPolicy = OverflowPolicy.cancel,
    this.completionPolicy = CompletionPolicy.eager,
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
        final constantMatcher = Matchers.equals(maskChar);
        _rawMatchers[i] = constantMatcher;
        lastMatcher = Matchers.or(constantMatcher, lastMatcher);
      }
      _positionMatchers[i] = lastMatcher;
    }
  }

  @override
  String deformat(String text) {
    final length = min(text.length, mask.length);
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final char = text[i];
      final isVariable = maskCharMap.containsKey(mask[i]);
      if (isVariable) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  bool get _appendFallback =>
      completionPolicy == CompletionPolicy.eagerIfFallback || completionPolicy == CompletionPolicy.eager;

  bool get _appendConstant =>
      completionPolicy == CompletionPolicy.lazyIfFallback || completionPolicy == CompletionPolicy.eager;

  String _getConstantCharsBetween(int from, int to, {bool acceptFallback = true, bool acceptConstant = true}) {
    final buffer = StringBuffer();
    for (int i = from; i < to; i++) {
      final char = mask[i];
      final fallback = fallbackMap[char];
      if (fallback != null && acceptFallback) {
        buffer.write(fallback);
        continue;
      }
      final isVariable = maskCharMap.containsKey(char);
      if (isVariable || !acceptConstant) {
        break;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatUpdate(TextEditingContext context) {
    initialize();
    final inserted = context.change.type.isInsert;
    int resultLength = 0;
    return streamingEditUpdate(context, (char) {
      if (char == eol) {
        // Handle end of line - check if we need to append constant chars
        final constantChars = _getConstantCharsBetween(
          resultLength,
          mask.length,
          acceptFallback: _appendFallback,
          acceptConstant: _appendConstant,
        );
        final pureConstantChars = _getConstantCharsBetween(
          resultLength,
          mask.length,
          acceptFallback: false,
          acceptConstant: _appendConstant,
        );
        return StreamStepResult(
          sequence: inserted ? constantChars : '',
          cursorShift: inserted ? pureConstantChars.length : 0,
        );
      }

      if (resultLength >= mask.length) {
        if (overflowPolicy == OverflowPolicy.cancel) {
          throw CancelException();
        }
        return StreamStepResult(sequence: '');
      }

      // Reject non-matching characters
      final matcher = _positionMatchers[resultLength];
      if (!matcher(char)) {
        return StreamStepResult(sequence: '');
      }

      // Find first matching position
      final index = _rawMatchers.indexWhere((matcher) => matcher(char), resultLength);
      final constantChars = _getConstantCharsBetween(resultLength, index);
      resultLength = index + 1;
      return StreamStepResult(sequence: constantChars + char);
    });
  }
}
