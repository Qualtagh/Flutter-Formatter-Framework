typedef Matcher = bool Function(String char);

class Matchers {
  static Matcher set(Iterable<String> allowed) {
    final set = allowed is Set ? allowed : allowed.toSet();
    return (char) => set.contains(char);
  }

  static Matcher regex(RegExp regex) => (char) => regex.hasMatch(char);
  static Matcher equals(String value) => (char) => char == value;
  static Matcher not(Matcher matcher) => (char) => !matcher(char);

  // TODO: add optimization for set and equals
  static Matcher or(Matcher a, Matcher b) => (char) => a(char) || b(char);
  static Matcher and(Matcher a, Matcher b) => (char) => a(char) && b(char);
  static bool any(String char) => true;
  static bool none(String char) => false;
  static final Matcher digits = set(List.generate(10, (i) => i.toString()));
}
