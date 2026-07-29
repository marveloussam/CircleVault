import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    this.prefix,           // inline prefix widget (e.g. phone flag pill)
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
  final Widget? prefix;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            // Inline prefix (e.g. teal +234 pill from mockup)
            prefix: widget.prefix,
            prefixIcon: widget.prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    child: widget.prefixIcon!,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon != null
                    ? IconTheme(
                        data: const IconThemeData(
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        child: widget.suffixIcon!,
                      )
                    : null,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5), width: 1),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Teal pill prefix widget — matches the +234 badge in mockup screen 3.
class PhonePrefixPill extends StatelessWidget {
  const PhonePrefixPill({super.key, this.code = '+234'});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
