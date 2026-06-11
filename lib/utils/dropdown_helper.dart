T? safeDropdownValue<T>(T? value, List<T> allowedValues) {
  if (value == null) return null;

  final count = allowedValues.where((item) => item == value).length;
  if (count == 1) return value;

  return null;
}

List<T> uniqueDropdownValues<T>(Iterable<T> values) {
  return values.toSet().toList();
}