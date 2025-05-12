import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/change.dart';

/// A context for [formatUpdate] function of [Formatter].
///
/// It provides additional information compared to the standard [formatEditUpdate]'s
/// [oldInput] and [newInput] parameters.
///
/// Custom formatters can store their own data in the context too.
/// Consider adding extension methods for custom fields to get better usability.
///
/// Contexts have a hierarchical structure: children can access their parent's data.
class TextEditingContext {
  final Map<String, dynamic> _data;
  final TextEditingContext? parent;

  T? getValue<T>(String key) => _data[key] ?? parent?.getValue<T>(key);

  void setValue<T>(String key, T? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  TextEditingContext get root => parent?.root ?? this;

  /// Old text before any editing or formatting.
  /// Corresponds to [oldInput] of [TextInputFormatter.formatEditUpdate].
  TextEditingValue get old => getValue<TextEditingValue>('old')!;

  /// Text after raw editing but before any formatting.
  TextEditingValue get edited => getValue<TextEditingValue>('edited')!;

  /// Text after applying all prior formatters in the chain.
  /// Corresponds to [newInput] of [TextInputFormatter.formatEditUpdate].
  TextEditingValue get preformatted => getValue<TextEditingValue>('preformatted')!;
  set preformatted(TextEditingValue value) => setValue('preformatted', value);

  /// The change detected between [old] and [edited].
  Change get change => getValue<Change>('change')!;

  TextEditingContext({
    this.parent,
    TextEditingValue? old,
    TextEditingValue? edited,
    TextEditingValue? preformatted,
    Change? change,
  }) : assert(parent != null || old != null && edited != null && preformatted != null && change != null),
       _data = {'old': old, 'edited': edited, 'preformatted': preformatted, 'change': change};
}
