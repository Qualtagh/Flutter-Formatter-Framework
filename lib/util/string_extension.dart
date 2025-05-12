final _nonDigitsRegex = RegExp(r'[^\d]+');

extension StringExtension on String {
  /// Returns a new string with all non-digit characters removed.
  String digitsOnly() => replaceAll(_nonDigitsRegex, '');
}
