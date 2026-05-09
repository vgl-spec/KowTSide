import 'dart:convert';
import 'dart:html' as html;

Future<void> downloadCsvFile({
  required String filename,
  required String csvContent,
}) async {
  final normalizedName = filename.toLowerCase().endsWith('.csv')
      ? filename
      : '$filename.csv';
  final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', normalizedName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadBinaryFile({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
