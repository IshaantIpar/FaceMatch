import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickReferencePhoto() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
  }
}
