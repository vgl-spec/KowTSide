import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

const int _maxImportFileBytes = 20 * 1024 * 1024;
const _allowedImportExtensions = <String>{
  '.pdf',
  '.doc',
  '.docx',
  '.ppt',
  '.pptx',
  '.csv',
  '.xlsx',
};

class PickedImportFileData {
  final String name;
  final List<int> bytes;

  const PickedImportFileData({required this.name, required this.bytes});
}

Future<PickedImportFileData?> pickImportFileData() async {
  final input = html.FileUploadInputElement()
    ..accept =
        '.pdf,.doc,.docx,.ppt,.pptx,.csv,text/csv,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ..multiple = false;
  input.click();

  await input.onChange.first;
  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null;
  }
  _validateImportFile(file);

  final reader = html.FileReader();
  final completer = Completer<PickedImportFileData?>();

  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(
        PickedImportFileData(name: file.name, bytes: result.asUint8List()),
      );
      return;
    }

    if (result is! List<int>) {
      completer.complete(null);
      return;
    }

    completer.complete(PickedImportFileData(name: file.name, bytes: result));
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsArrayBuffer(file);

  return completer.future;
}

final StreamController<PickedImportFileData> _dropController =
    StreamController<PickedImportFileData>.broadcast();
bool _dropListenersInstalled = false;

Stream<PickedImportFileData> watchImportFileDrops() {
  if (!_dropListenersInstalled) {
    _dropListenersInstalled = true;
    html.document.body?.onDragOver.listen((event) {
      event.preventDefault();
    });
    html.document.body?.onDrop.listen((event) async {
      event.preventDefault();
      final files = event.dataTransfer.files;
      final file = files != null && files.isNotEmpty ? files.first : null;
      if (file == null) {
        return;
      }
      _validateImportFile(file);

      final picked = await _readFile(file);
      if (picked != null) {
        _dropController.add(picked);
      }
    });
  }
  return _dropController.stream;
}

void _validateImportFile(html.File file) {
  final lowerName = file.name.toLowerCase();
  final hasAllowedExtension = _allowedImportExtensions.any(lowerName.endsWith);
  if (!hasAllowedExtension) {
    throw const FormatException(
      'Unsupported file format. Use PDF, DOC, DOCX, PPT, PPTX, CSV, or XLSX.',
    );
  }
  if (file.size > _maxImportFileBytes) {
    throw const FormatException('File exceeds 20MB limit.');
  }
}

Future<PickedImportFileData?> _readFile(html.File file) {
  final reader = html.FileReader();
  final completer = Completer<PickedImportFileData?>();

  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(
        PickedImportFileData(name: file.name, bytes: result.asUint8List()),
      );
      return;
    }
    if (result is List<int>) {
      completer.complete(PickedImportFileData(name: file.name, bytes: result));
      return;
    }
    completer.complete(null);
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsArrayBuffer(file);
  return completer.future;
}
