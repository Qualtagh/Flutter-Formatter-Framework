import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';

/// A formatter that applies a chain of given formatters to the text.
/// It's similar to standard Flutter's approach of using a list of formatters,
/// but it passes a more detailed [TextEditingContext] to each formatter.
class ChainFormatter extends Formatter {
  final List<TextInputFormatter> chain;

  const ChainFormatter(this.chain);

  @override
  String deformat(String text) {
    String result = text;
    for (int i = chain.length - 1; i >= 0; i--) {
      final formatter = chain[i];
      if (formatter is Formatter) {
        result = formatter.deformat(result);
      }
    }
    return result;
  }

  @override
  TextEditingValue formatUpdate(TextEditingContext context) {
    for (final formatter in chain) {
      if (formatter is Formatter) {
        context.preformatted = formatter.formatUpdate(TextEditingContext(parent: context));
      } else {
        context.preformatted = formatter.formatEditUpdate(context.old, context.preformatted);
      }
    }
    return context.preformatted;
  }
}
