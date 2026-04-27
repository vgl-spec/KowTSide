class PickedImportFileData {
  final String name;
  final List<int> bytes;

  const PickedImportFileData({required this.name, required this.bytes});
}

Future<PickedImportFileData?> pickImportFileData() async => null;

Stream<PickedImportFileData> watchImportFileDrops() => const Stream.empty();
