import 'package:dio/dio.dart';

import 'api_client.dart';
import 'constants.dart';
import 'image_picker_service.dart';

class QuestionImageService {
  QuestionImageService._();

  static Future<String?> pickAndUploadImage() async {
    final selected = await pickImageData();
    if (selected == null) {
      return null;
    }

    if (ApiConstants.frontendOnly) {
      return selected.dataUrl;
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        selected.bytes,
        filename: selected.name,
      ),
    });

    final response = await dio.post(
      ApiConstants.questionUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data as Map<String, dynamic>;
    return data['url'] as String?;
  }
}
