final nonDigitsRegex = RegExp(r'[^\d]+');

extension StringExtension on String {
  String digitsOnly() => replaceAll(nonDigitsRegex, '');
}
