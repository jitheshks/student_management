import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  // Restored options
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;

  // Password options
  final bool obscureText;
  final bool hasToggle;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.suffixIcon,
    this.obscureText = false,
    this.hasToggle = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _obscured = !_obscured),
      tooltip: _obscured ? 'Show' : 'Hide',
    );

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      focusNode: widget.focusNode,
      obscureText: _obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(widget.prefixIcon),
        suffixIcon: widget.suffixIcon ?? (widget.hasToggle ? toggle : null),
      ),
    );
  }
}
