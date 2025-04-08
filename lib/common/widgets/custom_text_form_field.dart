import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomTextFormField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final TextCapitalization? textCapitalization;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final bool? obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final FocusNode? focusNode;
  final ValueSetter<PointerEvent>? onTapOutside;
  final VoidCallback? onEditingComplete;
  final EdgeInsetsGeometry? padding; // 👈 Novo parâmetro

  const CustomTextFormField({
    super.key,
    this.hintText,
    this.labelText,
    this.textCapitalization,
    this.controller,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
    this.suffixIcon,
    this.obscureText,
    this.inputFormatters,
    this.validator,
    this.helperText,
    this.onTap,
    this.readOnly = false,
    this.focusNode,
    this.onTapOutside,
    this.onEditingComplete,
    this.padding, // 👈 Novo parâmetro
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final defaultBorder = const OutlineInputBorder(
    borderSide: BorderSide(
      color: AppColors.greenOne,
    ),
  );

  String? _helperText;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _helperText = widget.helperText;
    _isObscure = widget.obscureText ?? true;
  }

  void _toggleObscure() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero, // 👈 Aplica padding se informado
      child: TextFormField(
        focusNode: widget.focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onEditingComplete: widget.onEditingComplete ??
            () {
              FocusScope.of(context).nextFocus();
            },
        onTapOutside: widget.onTapOutside ??
            (_) {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }
            },
        onChanged: (value) {
          if (value.length == 1) {
            setState(() {
              _helperText = null;
            });
          } else if (value.isEmpty) {
            setState(() {
              _helperText = widget.helperText;
            });
          }
        },
        validator: widget.validator,
        style: AppTextStyles.inputText.copyWith(color: AppColors.greenOne),
        inputFormatters: widget.inputFormatters,
        obscureText: widget.obscureText == true ? _isObscure : false,
        textInputAction: widget.textInputAction,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        textCapitalization:
            widget.textCapitalization ?? TextCapitalization.none,
        decoration: InputDecoration(
          errorMaxLines: 3,
          helperText: _helperText,
          helperMaxLines: 3,
          suffixIcon: widget.obscureText == true
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.darkGreen,
                  ),
                  onPressed: _toggleObscure,
                )
              : widget.suffixIcon,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.darkGreen),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.labelText?.toUpperCase(),
          labelStyle: AppTextStyles.inputLabelText.copyWith(
            color: AppColors.grey,
          ),
          focusedBorder: defaultBorder,
          errorBorder: defaultBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: defaultBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.error),
          ),
          enabledBorder: defaultBorder,
          disabledBorder: defaultBorder,
        ),
      ),
    );
  }
}
