import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/formatters/text_editing_context.dart';

class ChainFormatter extends Formatter {
  final List<TextInputFormatter> chain;

  ChainFormatter(this.chain);

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
