import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_text_form_field.dart';
import 'package:student_management/controller/student_form_page_controller.dart';
import 'package:student_management/controller/staff_form_page_controller.dart';

class UserFormPageScreen extends StatelessWidget {
  final String role;
  final Map<String, dynamic>? data;

  const UserFormPageScreen({super.key, required this.role, this.data});

  @override
  Widget build(BuildContext context) {
    final isStudent = role == 'student';

    // Dynamically use the appropriate controller
    final controller = isStudent
        ? Provider.of<StudentFormPageController>(context, listen: false)
        : Provider.of<StaffFormPageController>(context, listen: false);

    if (data != null && (controller as dynamic).isEditing == false) {
      if (isStudent) {
        (controller as StudentFormPageController).loadStudentData(data!);
      } else {
        (controller as StaffFormPageController).loadStaffData(data!);
      }
    }

    final isEditing = (controller as dynamic).isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit ${role.capitalize()}' : 'Add ${role.capitalize()}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: (controller as dynamic).formKey,
          child: Column(
            children: [
              // Avatar picker
              isStudent
                  ? Consumer<StudentFormPageController>(
                      builder: (_, studentController, __) => GestureDetector(
                        onTap: () async =>
                            await studentController.pickAndCropImage(context),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: studentController.profileImage != null
                              ? FileImage(studentController.profileImage!)
                              : (studentController.profileImageUrl?.isNotEmpty ?? false)
                                  ? NetworkImage(studentController.profileImageUrl!)
                                  : const AssetImage('assets/user_image/user.png')
                                      as ImageProvider,
                        ),
                      ),
                    )
                  : Consumer<StaffFormPageController>(
                      builder: (_, staffController, __) => GestureDetector(
                        onTap: () async =>
                            await staffController.pickAndCropImage(context),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: staffController.profileImage != null
                              ? FileImage(staffController.profileImage!)
                              : (staffController.profileImageUrl?.isNotEmpty ?? false)
                                  ? NetworkImage(staffController.profileImageUrl!)
                                  : const AssetImage('assets/user_image/user.png')
                                      as ImageProvider,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Form fields
              CustomTextFormField(
                controller: (controller as dynamic).firstNameController,
                labelText: 'First Name',
                prefixIcon: Icons.person,
                keyboardType: TextInputType.name,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter First Name' : null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
                  TextInputFormatter.withFunction(
                    (oldVal, newVal) => newVal.text.isEmpty
                        ? newVal
                        : newVal.copyWith(
                            text:
                                '${newVal.text[0].toUpperCase()}${newVal.text.substring(1)}',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              CustomTextFormField(
                controller: (controller as dynamic).lastNameController,
                labelText: 'Last Name',
                prefixIcon: Icons.person,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter Last Name' : null,
              ),
              const SizedBox(height: 10),

              CustomTextFormField(
                controller: (controller as dynamic).addressController,
                labelText: 'Address',
                prefixIcon: Icons.home,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 10),

              CustomTextFormField(
                controller: (controller as dynamic).phoneNumberController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter phone number';
                  if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value))
                    return 'Enter a valid phone number';
                  return null;
                },
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 10),

              CustomTextFormField(
                controller: (controller as dynamic).emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (value == null || value.isEmpty) return 'Please enter an email';
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: isStudent
                    ? (controller as dynamic).selectedStandard
                    : (controller as dynamic).designation,
                decoration: InputDecoration(
                  labelText: isStudent ? 'Standard' : 'Designation',
                  prefixIcon: Icon(isStudent ? Icons.school : Icons.work),
                  border: const OutlineInputBorder(),
                ),
                items: (isStudent
                        ? [
                            '1st',
                            '2nd',
                            '3rd',
                            '4th',
                            '5th',
                            '6th',
                            '7th',
                            '8th',
                            '9th',
                            '10th',
                          ]
                        : ['Staff', 'Librarian', 'Teacher'])
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (isStudent) {
                    (controller as dynamic).setStandard(value!);
                  } else {
                    (controller as dynamic).setDesignation(value!);
                  }
                },
              ),
              const SizedBox(height: 10),

              CustomTextFormField(
                controller: (controller as dynamic).dobController,
                labelText: 'Date of Birth',
                prefixIcon: Icons.calendar_today,
                readOnly: true,
                onTap: () => (controller as dynamic).selectDate(context),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please select Date of Birth' : null,
              ),
              const SizedBox(height: 20),

              // ✅ Updated Submit Button (Step 2 + Step 3)
              isStudent
                  ? Consumer<StudentFormPageController>(
                      builder: (context, c, _) => _buildSubmitButton(
                        context,
                        isEditing,
                        c.isSubmitting,
                        onPressed: () {
                          if (isEditing) {
                            (controller as StudentFormPageController)
                                .updateStudent(context);
                          } else {
                            (controller as StudentFormPageController)
                                .submitForm(context);
                          }
                        },
                      ),
                    )
                  : Consumer<StaffFormPageController>(
                      builder: (context, c, _) => _buildSubmitButton(
                        context,
                        isEditing,
                        c.isSubmitting,
                        onPressed: () {
                          if (isEditing) {
                            (controller as StaffFormPageController)
                                .updateStaff(context);
                          } else {
                            (controller as StaffFormPageController)
                                .submitForm(context);
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Step 3: Reusable Submit Button
  Widget _buildSubmitButton(
    BuildContext context,
    bool isEditing,
    bool isSubmitting, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
  onPressed: isSubmitting ? null : onPressed,
  child: isSubmitting
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white, // optional, matches theme
          ),
        )
      : Text(isEditing ? 'Update' : 'Create'),
)

    );
  }
}

// Extension
extension StringCasing on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
