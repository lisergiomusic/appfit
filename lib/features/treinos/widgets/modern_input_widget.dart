import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ModernInputWidget extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? autoSuffix;

  const ModernInputWidget({
    required this.initialValue,
    required this.onChanged,
    this.autoSuffix,
    super.key,
  });

  @override
  State<ModernInputWidget> createState() => _ModernInputWidgetState();
}

class _ModernInputWidgetState extends State<ModernInputWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
    if (!_focusNode.hasFocus && widget.autoSuffix != null) {
      final text = _controller.text.trim();
      if (RegExp(r'\d$').hasMatch(text)) {
        final newText = '$text${widget.autoSuffix}';
        setState(() => _controller.text = newText);
        widget.onChanged(newText);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ModernInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      if (!_focusNode.hasFocus) _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return SizedBox(
      height: 36,
      child: Center(
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.text,
          cursorColor: AppColors.primary,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isFocused
                ? AppColors.primary.withAlpha(35)
                : Colors.white.withAlpha(15),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(30),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary.withAlpha(150),
                width: 0.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
