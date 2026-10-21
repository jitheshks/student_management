import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/constants/app_constants.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/shared/models/staff.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/avatar_picker.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  final Staff? initialStaff;

  const StaffFormScreen({super.key, this.initialStaff});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;

  static const List<String> _designationOptions = [
    ...AppConstants.designations,
  ];

  @override
  void initState() {
    super.initState();
    final staff = widget.initialStaff;

    _firstNameController = TextEditingController(text: staff?.firstName ?? '');
    _lastNameController = TextEditingController(text: staff?.lastName ?? '');
    _addressController = TextEditingController(text: staff?.address ?? '');
    _phoneController = TextEditingController(text: staff?.phone ?? '');
    _emailController = TextEditingController(text: staff?.email ?? '');

    String dobFormatted = '';
    if (staff?.dob != null) {
      dobFormatted = DateFormat('d/M/yyyy').format(staff!.dob!);
    }
    _dobController = TextEditingController(text: dobFormatted);

    Future.microtask(() {
      ref.read(staffFormControllerProvider.notifier).init(staff);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate =
        widget.initialStaff?.dob ?? DateTime(1990, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formController = ref.read(staffFormControllerProvider.notifier);
    final state = ref.read(staffFormControllerProvider);

    final designation = state.selectedDesignation;
    if (designation == null || designation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a designation.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    bool success = false;

    if (state.isEditing) {
      success = await formController.updateStaff(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        designation: designation,
        dobString: _dobController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      success = await formController.createStaff(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        designation: designation,
        dobString: _dobController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    if (!mounted) return;

    final currentState = ref.read(staffFormControllerProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.isEditing
                ? 'Staff updated successfully!'
                : 'Staff created successfully!',
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
    final state = ref.watch(staffFormControllerProvider);
    final formController = ref.read(staffFormControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isEditing ? 'Edit Staff' : 'Add Staff',
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
                  // Avatar Picker
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space20,
                      horizontal: AppSpacing.space16,
                    ),
                    child: Column(
                      children: [
                        AvatarPicker(
                          imageFile: state.avatarFile,
                          networkImageUrl: state.networkImageUrl,
                          onImageSelected: formController.setAvatar,
                          size: 110,
                        ),
                        AppSpacing.gapH8,
                        Text(
                          state.isEditing
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
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Please enter first name'
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
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Please enter last name'
                                    : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z\s]"),
                          ),
                        ],
                      );

                      final emailField = TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: state.isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(val.trim())) {
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!RegExp(r'^[0-9]{10,15}$').hasMatch(val.trim())) {
                            return 'Enter a valid phone number (10-15 digits)';
                          }
                          return null;
                        },
                      );

                      final designationField = DropdownButtonFormField<String>(
                        initialValue:
                            state.selectedDesignation != null &&
                                    _designationOptions.contains(
                                      state.selectedDesignation,
                                    )
                                ? state.selectedDesignation
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Designation',
                          prefixIcon: Icon(Icons.work),
                        ),
                        items:
                            _designationOptions
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) formController.setDesignation(val);
                        },
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Please select a designation'
                                    : null,
                      );

                      final dobField = TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth (d/M/yyyy)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Please select date of birth'
                                    : null,
                      );

                      final addressField = TextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
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
                                Expanded(child: designationField),
                                AppSpacing.gapW16,
                                Expanded(child: dobField),
                              ],
                            ),
                            AppSpacing.gapH16,
                            addressField,
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
                            emailField,
                            AppSpacing.gapH12,
                            designationField,
                            AppSpacing.gapH12,
                            dobField,
                            AppSpacing.gapH12,
                            phoneField,
                            AppSpacing.gapH12,
                            addressField,
                          ],
                        );
                      }
                    },
                  ),
                  AppSpacing.gapH24,

                  // Submit Button
                  AppButton(
                    text: state.isEditing ? 'Update Staff' : 'Create Staff',
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _handleSubmit,
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
