// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/widgets/custom_text_form_field.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController? controller;
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final ValueSetter<PointerEvent>? onTapOutside;
  final VoidCallback? onEditingComplete;

  const PasswordFormField({
    super.key,
    this.controller,
    this.padding,
    this.hintText,
    this.labelText,
    this.validator,
    this.helperText,
    this.focusNode,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete ??
          () {
            FocusScope.of(context).nextFocus();
          },
      focusNode: widget.focusNode,
      onTapOutside: widget.onTapOutside ??
          (_) {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
            }
          },
      helperText: widget.helperText,
      validator: widget.validator,
      obscureText: isHidden,
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      suffixIcon: InkWell(
        borderRadius: BorderRadius.circular(23.0),
        onTap: () {
          log("pressed");
          setState(() {
            isHidden = !isHidden;
          }); 
        },
        child: Icon(
          isHidden ? Icons.visibility : Icons.visibility_off,
          color: AppColors.greenTwo,
        ),
      ),
    );
  }
}