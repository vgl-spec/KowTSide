int? parseStudentId(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final canonicalMatch = RegExp(r'^STU-(\d+)$', caseSensitive: false)
        .firstMatch(trimmed);
    if (canonicalMatch != null) {
      return int.tryParse(canonicalMatch.group(1)!);
    }

    return int.tryParse(trimmed);
  }

  return null;
}

String formatStudentId(int studId) => 'STU-$studId';
