import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class PickedImageData {
  final String name;
  final List<int> bytes;
  final String dataUrl;

  const PickedImageData({
    required this.name,
    required this.bytes,
    required this.dataUrl,
  });
}

Future<PickedImageData?> pickImageData() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  await input.onChange.first;
  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null;
  }

  final reader = html.FileReader();
  final completer = Completer<PickedImageData?>();

  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is! String || !result.contains(',')) {
      completer.complete(null);
      return;
    }

    final encoded = result.split(',').last;
    completer.complete(
      PickedImageData(
        name: file.name,
        bytes: base64Decode(encoded),
        dataUrl: result,
      ),
    );
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsDataUrl(file);

  return completer.future;
}
