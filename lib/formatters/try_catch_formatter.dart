import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/cancel_exception.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';

typedef OnErrorFunction = TextEditingValue Function(TextEditingContext context, Object error, StackTrace stack);

TextEditingValue _defaultOnError(context, error, stack) {
  if (error is CancelException) {
    return context.old;
  } else {
    throw error;
  }
}

/// Catch inner formatter exceptions. Usage example:
/// ```dart
/// TextFormField(
///   initialValue: '12/12/2023',
///   inputFormatters: FormattersChain([
///     TryCatchFormatter(
///       ChainFormatter([
///         MyFormatter1(),
///         MyFormatter2(),
///         Formatter.withFunction((context) {
///           throw CancelException();
///         }),
///         NeverCalledFormatter(),
///       ]),
///       onError: (context, error, stack) {
///         // Handle error
///         return context.old;
///       },
///     ),
///     MyFinallyCleanupFormatter(),
///   ]),
/// )
/// ```
/// In this example:
/// - `MyFormatter1` and `MyFormatter2` will be called,
///   but their output will be cancelled by the `CancelException`.
/// - The `NeverCalledFormatter` will not be called.
/// - The `onError` function will be called with the `CancelException`.
/// - The `MyFinallyCleanupFormatter` will be called after the `TryCatchFormatter`.
///   It will receive the original text as input (because `onError` returns `context.old`).
///   This is the only formatter which output will be eventually applied to the text.
class TryCatchFormatter extends Formatter {
  final Formatter body;
  final OnErrorFunction onError;

  const TryCatchFormatter(this.body, {this.onError = _defaultOnError});

  @override
  String deformat(String text) => body.deformat(text);

  @override
  TextEditingValue formatUpdate(TextEditingContext context) {
    try {
      return body.formatUpdate(context);
    } catch (e, stack) {
      return onError(context, e, stack);
    }
  }
}
