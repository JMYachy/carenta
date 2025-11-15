num parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0;
  }
  return 0;
}
