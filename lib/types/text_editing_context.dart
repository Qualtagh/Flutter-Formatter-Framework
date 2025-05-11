import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/change.dart';

class TextEditingContext {
  /// Old text before any editing or formatting.
  /// Corresponds to [oldInput] of [TextInputFormatter.formatEditUpdate].
  final TextEditingValue old;

  /// Text after raw editing but before any formatting.
  final TextEditingValue edited;

  /// Text after applying all prior formatters in the chain.
  /// Corresponds to [newInput] of [TextInputFormatter.formatEditUpdate].
  final TextEditingValue preformatted;

  /// The change detected between [old] and [edited].
  final Change change;

  TextEditingContext({required this.old, required this.edited, required this.preformatted, required this.change});

  TextEditingContext copyWith({TextEditingValue? preformatted}) {
    return TextEditingContext(
      old: old,
      edited: edited,
      preformatted: preformatted ?? this.preformatted,
      change: change,
    );
  }
}
