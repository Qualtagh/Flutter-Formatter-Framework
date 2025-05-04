import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/change_type.dart';

class TextEditingContext {
  final TextEditingValue old;
  final TextEditingValue edited;
  final TextEditingValue preformatted;
  final ChangeType changeType;

  TextEditingContext({required this.old, required this.edited, required this.preformatted, required this.changeType});

  TextEditingContext copyWith({TextEditingValue? preformatted}) {
    return TextEditingContext(
      old: old,
      edited: edited,
      preformatted: preformatted ?? this.preformatted,
      changeType: changeType,
    );
  }
}
