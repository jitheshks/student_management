import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:student_management/model/student_model.dart';

class StudentFormPageController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Form input controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final attendanceController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();

  bool isSubmitting = false;
  File? _profileImage;
  String? profileImageUrl;
  String? selectedStandard;
  String? studentId;
  bool _isEditing = false;

  File? get profileImage => _profileImage;
  bool get isEditing => _isEditing;

  void setEditing(bool value) {
    _isEditing = value;
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      dobController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      notifyListeners();
    }
  }

  void setStandard(String standard) {
    selectedStandard = standard;
    notifyListeners();
  }

  Future<void> pickAndCropImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        _showErrorMessage(context, "No image selected!");
        return;
      }

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false),
        ],
      );

      if (croppedFile != null) {
        setProfileImage(File(croppedFile.path));
        if (studentId != null) {
          await _uploadAndSaveProfileImage();
        }
      } else {
        _showErrorMessage(context, "Image cropping canceled!");
      }
    } catch (e) {
      _showErrorMessage(context, "Error picking image: $e");
    }
  }

  Future<String?> uploadProfileImage(String studentId, File imageFile) async {
    try {
      final fileName = '$studentId.jpg';
      await Supabase.instance.client.storage
          .from('profile_pictures')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('profile_pictures')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _uploadAndSaveProfileImage() async {
    if (_profileImage != null && studentId != null) {
      final newProfileImageUrl = await uploadProfileImage(
        studentId!,
        _profileImage!,
      );
      if (newProfileImageUrl != null) {
        profileImageUrl = newProfileImageUrl;
        await Supabase.instance.client
            .from('students')
            .update({'profile_image_url': profileImageUrl})
            .eq('id', studentId!);
        notifyListeners();
      }
    }
  }

  Future<String> _generateUniqueRegisterNumber() async {
    final supabase = Supabase.instance.client;
    final response =
        await supabase
            .from('students')
            .select('register_number')
            .order('register_number', ascending: false)
            .limit(1)
            .maybeSingle();

    int lastNumber = 0;
    if (response != null && response['register_number'] != null) {
      final lastReg = response['register_number'] as String;
      lastNumber = int.tryParse(lastReg.substring(4)) ?? 0;
    }
    final newNumber = lastNumber + 1;
    final newRegister = '1080${newNumber.toString().padLeft(4, '0')}';

    return newRegister;
  }

  /// Create StudentModel from form fields
  StudentModel buildStudentModel({
    required String id,
    required String registerNumber,
  }) {
    DateTime? dob;
    if (dobController.text.isNotEmpty) {
      try {
        dob = DateFormat('d/M/yyyy').parse(dobController.text);
      } catch (_) {}
    }
    return StudentModel(
      id: id,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: addressController.text.trim(),
      phone: phoneNumberController.text.trim(),
      attendance: int.tryParse(attendanceController.text) ?? 0,
      email: emailController.text.trim().toLowerCase(),
      standard: selectedStandard ?? '',
      profileImageUrl: profileImageUrl,
      registerNumber: registerNumber,
      userId: id,
      dob: dob,
    );
  }

  Future<void> createStudent(BuildContext context) async {
    isSubmitting = true;
    notifyListeners();
    print('🟡 [createStudent] Starting student creation...');

    try {
      final supabase = Supabase.instance.client;

      // Collect and trim inputs
      final email = emailController.text.trim().toLowerCase();
      final firstName = firstNameController.text.trim();
      final dobInput = dobController.text.trim();
      final lastName = lastNameController.text.trim();
      final address = addressController.text.trim();
      final phone = phoneNumberController.text.trim();
      final attendance = int.tryParse(attendanceController.text) ?? 0;

      // Basic validation
      if (email.isEmpty ||
          firstName.isEmpty ||
          dobInput.isEmpty ||
          !dobInput.contains('/')) {
        _showErrorMessage(context, "Please fill all required fields properly.");
        return;
      }

      // Convert DOB to ISO format
      late String dob;
      try {
        dob =
            DateFormat(
              'd/M/yyyy',
            ).parse(dobInput).toIso8601String().split('T').first;
      } catch (_) {
        _showErrorMessage(context, "Invalid DOB format. Use DD/MM/YYYY.");
        return;
      }

      // Step 1: Check if email already exists in `users` or `students`
      print('🔎 [createStudent] Checking for existing email: $email');

      final existingUser =
          await supabase
              .from('users')
              .select()
              .eq('email', email)
              .maybeSingle();

      final existingStudent =
          await supabase
              .from('students')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (existingUser != null || existingStudent != null) {
        _showErrorMessage(
          context,
          'This email is already registered in database.',
        );
        return;
      }

      // Step 2: Sign up user in Supabase Auth
      final password = "$firstName@${dobInput.split('/').last}";
      print('🔐 [createStudent] Signing up user with email: $email');

      await supabase.auth.signUp(email: email, password: password);

      // Step 3: Sign in to get user ID and session
      final loginResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (loginResponse.user == null || loginResponse.session == null) {
        throw Exception("Login failed after sign up.");
      }

      final newStudentId = loginResponse.user!.id;
      print('✅ [createStudent] Signed in. New student ID: $newStudentId');

      // Step 4: Double-check students table by ID
      final studentCheck =
          await supabase
              .from('students')
              .select()
              .eq('id', newStudentId)
              .maybeSingle();

      if (studentCheck != null) {
        _showErrorMessage(context, "Student with this ID already exists.");
        return;
      }

      // Step 5: Insert into `users` table
      print('📥 [createStudent] Inserting into `users` table...');
      await supabase.from('users').insert({
        'id': newStudentId,
        'email': email,
        'role': 'student',
      });

      // Step 6: Generate register number
      final registerNumber = await _generateUniqueRegisterNumber();
      print('🆔 [createStudent] Generated register number: $registerNumber');

   // Step 7: Insert into `students` table
print('📥 [createStudent] Inserting into students table...');
await supabase.from('students').insert({
  'id': newStudentId,
  'user_id': newStudentId, // IMPORTANT: link to Auth UID
  'first_name': firstName,
  'last_name': lastName,
  'address': address,
  'phone': phone,
  'register_number': registerNumber,
  'attendance': attendance,
  'email': email, // already lowercased
  'standard': selectedStandard,
  'dob': dob, // yyyy-mm-dd
  'created_at': DateTime.now().toIso8601String(),
});

      studentId = newStudentId;

      // Step 8: Upload profile image
      print('📤 [createStudent] Uploading profile image...');
      await _uploadAndSaveProfileImage();

      _showSuccessMessage(context, 'Student added successfully!');
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ [createStudent] Navigation to /studentManagement');
      Navigator.pop(context, true);

      resetForm();
      print('✅ [createStudent] Form reset and done.');
    } catch (e) {
      final err = e.toString();
      print('❌ [createStudent] Error: $err');

      if (err.contains('User already registered') ||
          err.contains('duplicate key value') ||
          err.contains('email already in use')) {
        _showErrorMessage(context, 'This email is already registered.');
      } else {
        _showErrorMessage(context, 'Error adding student: $err');
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
      print('🔚 [createStudent] Done (finally block).');
    }
  }

  void submitForm(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      if (_isEditing) {
        await updateStudent(context);
      } else {
        await createStudent(context);
      }
    } else {
      _showErrorMessage(context, 'Please fill all required fields correctly.');
    }
  }

  /// **Load Student Data**
  /// Accepts a StudentModel OR Map<String, dynamic> for editing
  void loadStudentData(dynamic studentData) {
    StudentModel? student;
    if (studentData is StudentModel) {
      student = studentData;
    } else if (studentData is Map<String, dynamic>) {
      student = StudentModel.fromJson(studentData);
    } else {
      debugPrint("Invalid studentData type provided to loadStudentData.");
      return;
    }
    debugPrint("Loaded Student Data: $student");

    studentId = student.id;
    firstNameController.text = student.firstName;
    lastNameController.text = student.lastName;
    addressController.text = student.address ?? '';
    phoneNumberController.text = student.phone ?? '';
    attendanceController.text = student.attendance.toString();
    emailController.text = student.email;
    dobController.text =
        student.dob != null
            ? DateFormat('dd/MM/yyyy').format(student.dob!)
            : '';
    selectedStandard = student.standard;
    profileImageUrl = student.profileImageUrl ?? '';

    _isEditing = (studentId ?? '').isNotEmpty;
    Future.microtask(() => notifyListeners());
  }

  Future<void> updateStudent(BuildContext context) async {
  if (studentId == null) {
    _showErrorMessage(context, 'Error: No student selected for update.');
    return;
  }
  try {
    if (_profileImage != null) {
      await _uploadAndSaveProfileImage();
    }

    // Normalize DOB to yyyy-MM-dd if provided as dd/MM/yyyy
    String? normalizedDob;
    final dobText = dobController.text.trim();
    if (dobText.isNotEmpty) {
      try {
        // try dd/MM/yyyy first
        final parsed = DateFormat('dd/MM/yyyy').parse(dobText);
        normalizedDob = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        // if it's already iso-like (yyyy-MM-dd), keep as-is
        normalizedDob = dobText;
      }
    }

    final updatedData = {
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'address': addressController.text.trim(),
      'phone': phoneNumberController.text.trim(),
      'attendance': int.tryParse(attendanceController.text) ?? 0,
      'email': emailController.text.trim().toLowerCase(),
      'standard': selectedStandard,
      if (normalizedDob != null) 'dob': normalizedDob,
      'profile_image_url': profileImageUrl,
    };

    debugPrint("Updating student with data: $updatedData");
    await Supabase.instance.client
        .from('students')
        .update(updatedData)
        .eq('id', studentId!);

    Future.microtask(() {
      _showSuccessMessage(context, 'Student details updated successfully!');
      notifyListeners();
    });
  } catch (e) {
    _showErrorMessage(context, 'Error updating student: $e');
  }
}

  void resetForm() {
    formKey.currentState?.reset();
    firstNameController.clear();
    lastNameController.clear();
    addressController.clear();
    phoneNumberController.clear();
    attendanceController.clear();
    emailController.clear();
    dobController.clear();
    selectedStandard = null;
    _profileImage = null;
    profileImageUrl = null;
    studentId = null;
    _isEditing = false;
    isSubmitting = false;
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
