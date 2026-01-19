import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final TextEditingController controller;
  const CustomTextField({
    super.key,
    this.suffixIcon,
    this.maxLines,
    this.maxLength,
    required this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLength: maxLength,
      maxLines: maxLines,
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class CustomTagsTextfield extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;

  const CustomTagsTextfield({
    super.key,
    required this.hintText,
    required this.controller,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: suffixIcon != null
            ? Transform.scale(scale: 0.8, child: suffixIcon)
            : null,
        suffixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
