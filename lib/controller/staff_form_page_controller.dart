import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:student_management/model/staff_model.dart';

class StaffFormPageController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Form input controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();

  bool isSubmitting = false;
  File? _profileImage;
  String? profileImageUrl;
  String? staffId;
  String? designation;
  bool _isEditing = false;

  File? get profileImage => _profileImage;
  bool get isEditing => _isEditing;

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  void setDesignation(String value) {
    designation = value;
    notifyListeners();
  }

  void setProfileImage(File image) {
    _profileImage = image;
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      dobController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      notifyListeners();
    }
  }

  Future<void> pickAndCropImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false),
        ],
      );

      if (croppedFile != null) {
        setProfileImage(File(croppedFile.path));
        if (staffId != null) {
          await _uploadAndSaveProfileImage();
        }
      }
    } catch (e) {
      _showErrorMessage(context, 'Image error: $e');
    }
  }

  Future<(String url, String key)?> uploadProfileImage(String uid, File image) async {
  try {
    const bucketName = 'profile_pictures';
    const ext = 'jpg'; // stick to one extension
    final key = '$uid.$ext';

    final storage = Supabase.instance.client.storage.from(bucketName);
    await storage.upload(
      key,
      image,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = storage.getPublicUrl(key);
    return (url, key);
  } catch (e) {
    debugPrint('Upload error: $e');
    return null;
  }
}


Future<void> _uploadAndSaveProfileImage() async {
  if (_profileImage == null || staffId == null) return;

  final result = await uploadProfileImage(staffId!, _profileImage!);
  if (result != null) {
    final (url, key) = result;
    profileImageUrl = url;

    await Supabase.instance.client
        .from('staff')
        .update({
          'profile_image_url': url,
          'profile_image_key': key, // 🔑 store exact storage key
        })
        .eq('id', staffId!);

    notifyListeners();
  }
}


  /// Creates StaffModel from form fields
  StaffModel buildStaffModel({required String id}) {
    DateTime? dob;
    if (dobController.text.isNotEmpty) {
      try {
        dob = DateFormat('d/M/yyyy').parse(dobController.text);
      } catch (_) {}
    }
    return StaffModel(
      id: id,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: addressController.text.trim(),
      phone: phoneNumberController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      dob: dob,
      profileImageUrl: profileImageUrl,
      designation: designation ?? '',
    );
  }

  /// Create new staff (sign up, DB insert, upload avatar, etc.)
  Future<void> createStaff(BuildContext context) async {
  isSubmitting = true;
  notifyListeners();

  try {
    final supabase = Supabase.instance.client;

    final email = emailController.text.trim().toLowerCase();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final address = addressController.text.trim();
    final phone = phoneNumberController.text.trim();
    final dobInput = dobController.text.trim();

    if (email.isEmpty ||
        firstName.isEmpty ||
        dobInput.isEmpty ||
        designation == null) {
      _showErrorMessage(context, 'Fill all required fields.');
      return;
    }

    // Parse DOB
    late String dob;
    try {
      dob = DateFormat('d/M/yyyy').parse(dobInput).toIso8601String().split('T').first;
    } catch (_) {
      _showErrorMessage(context, 'Invalid DOB format.');
      return;
    }

    final existingUser = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    final existingStaff = await supabase
        .from('staff')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (existingUser != null || existingStaff != null) {
      _showErrorMessage(context, 'Email already registered.');
      return;
    }

    final password = "$firstName@${dobInput.split('/').last}";
    await supabase.auth.signUp(email: email, password: password);

    final loginResponse = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (loginResponse.user == null) {
      throw Exception('Sign in failed after sign up');
    }

    staffId = loginResponse.user!.id;

    await supabase.from('users').insert({
      'id': staffId,
      'email': email,
      'role': 'staff',
    });

    await supabase.from('staff').insert({
      'id': staffId,
      'user_id': staffId, // IMPORTANT: link to Auth UID
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'address': address,
      'phone': phone,
      'designation': designation,
      'dob': dob, // yyyy-MM-dd
      'created_at': DateTime.now().toIso8601String(),
    });

    await _uploadAndSaveProfileImage();

    _showSuccessMessage(context, 'Staff added successfully!');
    await Future.delayed(const Duration(milliseconds: 500));
    Navigator.pushReplacementNamed(context, '/staffManagement');
    resetForm();
  } catch (e) {
    _showErrorMessage(context, 'Error creating staff: $e');
  } finally {
    isSubmitting = false;
    notifyListeners();
  }
}


Future<void> updateStaff(BuildContext context) async {
  if (staffId == null) {
    _showErrorMessage(context, 'No staff ID found.');
    return;
  }

  isSubmitting = true;
  notifyListeners();

  try {
    // Upload avatar first if present
    if (_profileImage != null) {
      await _uploadAndSaveProfileImage();
    }

    // Normalize DOB
    String? normalizedDob;
    final dobText = dobController.text.trim();
    if (dobText.isNotEmpty) {
      try {
        final parsed = DateFormat('dd/MM/yyyy').parse(dobText);
        normalizedDob = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        normalizedDob = dobText;
      }
    }

    final updatedData = <String, dynamic>{
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'address': addressController.text.trim(),
      'phone': phoneNumberController.text.trim(),
      'email': emailController.text.trim().toLowerCase(),
      'designation': designation,
      'profile_image_url': profileImageUrl,
      if (normalizedDob != null) 'dob': normalizedDob,
      // profile_image_key is already handled in _uploadAndSaveProfileImage()
    };

    await Supabase.instance.client
        .from('staff')
        .update(updatedData)
        .eq('id', staffId!);

    _showSuccessMessage(context, 'Staff updated successfully!');
    notifyListeners();
  } catch (e) {
    _showErrorMessage(context, 'Update error: $e');
  } finally {
    isSubmitting = false;
    notifyListeners();
  }
}


  void submitForm(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      _isEditing ? await updateStaff(context) : await createStaff(context);
    } else {
      _showErrorMessage(context, 'Please correct the form fields.');
    }
  }

  /// Accepts StaffModel or Map<String, dynamic> for prefill/edit
  void loadStaffData(dynamic data) {
    StaffModel? staff;
    if (data is StaffModel) {
      staff = data;
    } else if (data is Map<String, dynamic>) {
      staff = StaffModel.fromJson(data);
    } else {
      debugPrint("Invalid data type for loadStaffData.");
      return;
    }

    staffId = staff.id;
    firstNameController.text = staff.firstName;
    lastNameController.text = staff.lastName;
    emailController.text = staff.email;
    addressController.text = staff.address ?? '';
    phoneNumberController.text = staff.phone ?? '';
    dobController.text =
        staff.dob != null ? DateFormat('dd/MM/yyyy').format(staff.dob!) : '';
    designation = staff.designation;
    profileImageUrl = staff.profileImageUrl ?? '';
    _isEditing = staffId != null;

    Future.microtask(() => notifyListeners());
  }

  void resetForm() {
    formKey.currentState?.reset();
    firstNameController.clear();
    lastNameController.clear();
    addressController.clear();
    phoneNumberController.clear();
    emailController.clear();
    dobController.clear();
    designation = null;
    _profileImage = null;
    profileImageUrl = null;
    staffId = null;
    _isEditing = false;
    notifyListeners();
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
