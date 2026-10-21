import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/constants/asset_constants.dart';

class AvatarPicker extends StatelessWidget {
  final File? imageFile;
  final String? networkImageUrl;
  final ValueChanged<File?> onImageSelected;
  final double size;

  const AvatarPicker({
    super.key,
    this.imageFile,
    this.networkImageUrl,
    required this.onImageSelected,
    this.size = 110,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        onImageSelected(File(croppedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  void _showPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Profile Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.slate100,
                      child: Icon(Icons.camera_alt, color: AppColors.primary),
                    ),
                    title: const Text('Take a Photo'),
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.slate100,
                      child: Icon(
                        Icons.photo_library,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Choose from Gallery'),
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),
                  if (imageFile != null || networkImageUrl != null)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEE2E2),
                        child: Icon(Icons.delete, color: AppColors.error),
                      ),
                      title: const Text(
                        'Remove Photo',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onImageSelected(null);
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(networkImageUrl!);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: AppColors.slate100,
              backgroundImage: imageProvider,
              child:
                  imageProvider == null
                      ? Image.asset(
                        AssetConstants.defaultUserAvatar,
                        fit: BoxFit.cover,
                        width: size * 0.7,
                      )
                      : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () => _showPickerModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
