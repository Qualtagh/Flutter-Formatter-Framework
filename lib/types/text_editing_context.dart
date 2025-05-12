import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/change.dart';

class TextEditingContext {
  final Map<String, dynamic> _data;

  T getValue<T>(String key) => _data[key] as T;

  void setValue<T>(String key, T value) => _data[key] = value;

  /// Old text before any editing or formatting.
  /// Corresponds to [oldInput] of [TextInputFormatter.formatEditUpdate].
  TextEditingValue get old => getValue<TextEditingValue>('old');

  /// Text after raw editing but before any formatting.
  TextEditingValue get edited => getValue<TextEditingValue>('edited');

  /// Text after applying all prior formatters in the chain.
  /// Corresponds to [newInput] of [TextInputFormatter.formatEditUpdate].
  TextEditingValue get preformatted => getValue<TextEditingValue>('preformatted');

  /// The change detected between [old] and [edited].
  Change get change => getValue<Change>('change');

  TextEditingContext({
    required TextEditingValue old,
    required TextEditingValue edited,
    required TextEditingValue preformatted,
    required Change change,
  }) : _data = {'old': old, 'edited': edited, 'preformatted': preformatted, 'change': change};

  TextEditingContext copyWith({TextEditingValue? preformatted}) {
    return TextEditingContext(
      old: old,
      edited: edited,
      preformatted: preformatted ?? this.preformatted,
      change: change,
    );
  }
}
