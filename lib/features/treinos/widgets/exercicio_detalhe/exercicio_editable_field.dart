import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class ExercicioEditableField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLength;
  final String? suffixText;
  final String? hintText;
  final TextInputType keyboardType;

  const ExercicioEditableField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.inputFormatters,
    this.maxLength = 8,
    this.suffixText,
    this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<ExercicioEditableField> createState() => _ExercicioEditableFieldState();
}

class _ExercicioEditableFieldState extends State<ExercicioEditableField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      hintText: _focusNode.hasFocus ? null : widget.hintText,
      hintStyle: TextStyle(
        color: Colors.white.withAlpha(40),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      suffixText: widget.suffixText,
      suffixStyle: const TextStyle(
        color: AppColors.labelSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.white.withAlpha(14), width: 1),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      onChanged: widget.onChanged,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
        ...?widget.inputFormatters,
      ],
      textAlign: TextAlign.center,
      keyboardType: widget.keyboardType,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _buildDecoration(),
    );
  }
}
