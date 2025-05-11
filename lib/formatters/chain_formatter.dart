import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';

class ChainFormatter extends Formatter {
  final List<TextInputFormatter> chain;

  ChainFormatter(this.chain);

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
    TextEditingValue formatted = context.preformatted;
    for (final formatter in chain) {
      if (formatter is Formatter) {
        formatted = formatter.formatUpdate(context.copyWith(preformatted: formatted));
      } else {
        formatted = formatter.formatEditUpdate(context.old, formatted);
      }
    }
    return formatted;
  }
}
