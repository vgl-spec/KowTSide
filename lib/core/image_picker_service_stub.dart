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
  return null;
}
