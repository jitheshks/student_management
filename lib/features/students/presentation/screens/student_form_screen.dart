import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/constants/app_constants.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/avatar_picker.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final Student? initialStudent;

  const StudentFormScreen({super.key, this.initialStudent});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _attendanceController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    final student = widget.initialStudent;

    _firstNameController = TextEditingController(
      text: student?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: student?.lastName ?? '');
    _addressController = TextEditingController(text: student?.address ?? '');
    _phoneController = TextEditingController(text: student?.phone ?? '');
    _attendanceController = TextEditingController(
      text: student != null ? student.attendance.toString() : '0',
    );
    _emailController = TextEditingController(text: student?.email ?? '');

    String dobFormatted = '';
    if (student?.dob != null) {
      dobFormatted = DateFormat('d/M/yyyy').format(student!.dob!);
    }
    _dobController = TextEditingController(text: dobFormatted);

    // Initialize controller state in microtask
    Future.microtask(() {
      ref.read(studentFormControllerProvider.notifier).init(student);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _attendanceController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate =
        widget.initialStudent?.dob ?? DateTime(2008, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formController = ref.read(studentFormControllerProvider.notifier);
    final state = ref.read(studentFormControllerProvider);

    final standard = state.selectedStandard;
    if (standard == null || standard.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a standard / class.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final attendance = int.tryParse(_attendanceController.text.trim()) ?? 0;
    bool success = false;

    if (state.isEditing) {
      success = await formController.updateStudent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        standard: standard,
        dobString: _dobController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        attendance: attendance,
      );
    } else {
      success = await formController.createStudent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        standard: standard,
        dobString: _dobController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        attendance: attendance,
      );
    }

    if (!mounted) return;

    final currentState = ref.read(studentFormControllerProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.isEditing
                ? 'Student updated successfully!'
                : 'Student created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (currentState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentState.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(studentFormControllerProvider);
    final formNotifier = ref.read(studentFormControllerProvider.notifier);
    final isEditing = formState.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Student' : 'Add Student',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space20,
          ),
          child: ResponsiveContent.form(
            maxContentWidth: 760,
            padding: EdgeInsets.zero,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Picker with cropping and preview
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space20,
                      horizontal: AppSpacing.space16,
                    ),
                    child: Column(
                      children: [
                        AvatarPicker(
                          imageFile: formState.avatarFile,
                          networkImageUrl: formState.networkImageUrl,
                          onImageSelected: formNotifier.setAvatar,
                          size: 110,
                        ),
                        AppSpacing.gapH8,
                        Text(
                          isEditing
                              ? 'Change Profile Picture'
                              : 'Upload Profile Picture',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH20,

                  // Responsive Form Fields: Single column on mobile, 2 columns on tablet/desktop
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMultiColumn = constraints.maxWidth >= 600;

                      final firstNameField = TextFormField(
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter First Name'
                                    : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z\s]"),
                          ),
                          TextInputFormatter.withFunction(
                            (oldVal, newVal) =>
                                newVal.text.isEmpty
                                    ? newVal
                                    : newVal.copyWith(
                                      text:
                                          '${newVal.text[0].toUpperCase()}${newVal.text.substring(1)}',
                                    ),
                          ),
                        ],
                      );

                      final lastNameField = TextFormField(
                        controller: _lastNameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter Last Name'
                                    : null,
                      );

                      final emailField = TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      );

                      final phoneField = TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!RegExp(
                            r'^[0-9]{10,15}$',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid phone number (10-15 digits)';
                          }
                          return null;
                        },
                      );

                      final standardField = DropdownButtonFormField<String>(
                        initialValue: formState.selectedStandard,
                        decoration: const InputDecoration(
                          labelText: 'Standard / Class',
                          prefixIcon: Icon(Icons.school),
                        ),
                        items:
                            AppConstants.standards
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.setStandard(val);
                        },
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Please select a standard'
                                    : null,
                      );

                      final dobField = TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth (DD/MM/YYYY)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select Date of Birth';
                          }
                          if (!value.contains('/')) {
                            return 'Format must be DD/MM/YYYY';
                          }
                          return null;
                        },
                      );

                      final attendanceField = TextFormField(
                        controller: _attendanceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Attendance (%)',
                          prefixIcon: Icon(Icons.assessment),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter attendance percentage';
                          }
                          final val = int.tryParse(value.trim());
                          if (val == null || val < 0 || val > 100) {
                            return 'Must be between 0 and 100';
                          }
                          return null;
                        },
                      );

                      final addressField = TextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter address'
                                    : null,
                      );

                      if (isMultiColumn) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: firstNameField),
                                AppSpacing.gapW16,
                                Expanded(child: lastNameField),
                              ],
                            ),
                            AppSpacing.gapH16,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: emailField),
                                AppSpacing.gapW16,
                                Expanded(child: phoneField),
                              ],
                            ),
                            AppSpacing.gapH16,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: standardField),
                                AppSpacing.gapW16,
                                Expanded(child: dobField),
                              ],
                            ),
                            AppSpacing.gapH16,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: attendanceField),
                                AppSpacing.gapW16,
                                Expanded(child: addressField),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Narrow mobile: single-column layout
                        return Column(
                          children: [
                            firstNameField,
                            AppSpacing.gapH12,
                            lastNameField,
                            AppSpacing.gapH12,
                            addressField,
                            AppSpacing.gapH12,
                            phoneField,
                            AppSpacing.gapH12,
                            emailField,
                            AppSpacing.gapH12,
                            standardField,
                            AppSpacing.gapH12,
                            dobField,
                            AppSpacing.gapH12,
                            attendanceField,
                          ],
                        );
                      }
                    },
                  ),
                  AppSpacing.gapH24,

                  // Submit Button
                  AppButton(
                    text: isEditing ? 'Update Student' : 'Create Student',
                    isLoading: formState.isSubmitting,
                    onPressed: formState.isSubmitting ? null : _handleSubmit,
                    height: 50,
                    borderRadius: AppRadius.r10,
                  ),
                  AppSpacing.gapH32,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
