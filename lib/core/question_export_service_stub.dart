Future<void> downloadCsvFile({
  required String filename,
  required String csvContent,
}) async {
  throw UnsupportedError('CSV export is only supported on web.');
}

Future<void> downloadBinaryFile({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('File download is only supported on web.');
}
