Future<void> downloadCsvFile({
  required String filename,
  required String csvContent,
}) async {
  throw UnsupportedError('CSV export is only supported on web.');
}
