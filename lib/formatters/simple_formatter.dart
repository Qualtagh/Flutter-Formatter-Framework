import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';

typedef FormatUpdateFunction = TextEditingValue Function(TextEditingContext context);
typedef DeformatFunction = String Function(String text);

class SimpleFormatter extends Formatter {
  final FormatUpdateFunction _formatUpdate;
  final DeformatFunction? _deformat;

  const SimpleFormatter(this._formatUpdate, [this._deformat]);

  @override
  TextEditingValue formatUpdate(TextEditingContext context) => _formatUpdate(context);

  @override
  String deformat(String text) => _deformat?.call(text) ?? text;
}
