import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Professional cream+lime text fields — one look for the whole app.
///
/// Prefer [MedAiTextField] / [MedAiLabeledField] for new UI.
/// Theme-level defaults live in [AppInputs.decorationTheme].
abstract final class AppInputs {
  static const double radius = AppRadius.m; // 16 — crisp, not pill-soft
  static const EdgeInsets contentPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  /// Light / dark [InputDecorationTheme] for [ThemeData].
  static InputDecorationTheme decorationTheme({required bool dark}) {
    final fill = dark ? AppColors.cardDark2 : Colors.white;
    final idle = dark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.grey200;
    final muted = dark ? AppColors.grey400 : AppColors.grey600;
    final err = dark ? const Color(0xFFFF6B6B) : AppColors.red;

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      isDense: false,
      contentPadding: contentPadding,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: muted.withValues(alpha: 0.55),
        fontWeight: FontWeight.w500,
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: muted,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.limeDeep,
        fontWeight: FontWeight.w800,
      ),
      helperStyle: AppTypography.caption.copyWith(color: muted),
      errorStyle: AppTypography.caption.copyWith(
        color: err,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: muted,
      suffixIconColor: muted,
      border: border(idle),
      enabledBorder: border(idle),
      disabledBorder: border(idle.withValues(alpha: 0.45)),
      focusedBorder: border(AppColors.limeDeep, width: 1.6),
      errorBorder: border(err),
      focusedErrorBorder: border(err, width: 1.6),
    );
  }

  /// Build a decoration that matches the global theme (for custom fields).
  static InputDecoration decoration({
    required BuildContext context,
    String? hintText,
    String? labelText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
    EdgeInsetsGeometry? contentPadding,
    bool dense = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? AppColors.cardDark2 : Colors.white;
    final idle = dark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.grey200;
    final err = AppColors.red;

    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      filled: filled,
      fillColor: fill,
      isDense: dense,
      contentPadding: contentPadding ?? AppInputs.contentPadding,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.grey600.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.limeDeep,
        fontWeight: FontWeight.w800,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixIconColor: AppColors.grey600,
      suffixIconColor: AppColors.grey600,
      border: border(idle),
      enabledBorder: border(idle),
      disabledBorder: border(idle.withValues(alpha: 0.45)),
      focusedBorder: border(AppColors.limeDeep, width: 1.6),
      errorBorder: border(err),
      focusedErrorBorder: border(err, width: 1.6),
    );
  }

  static TextStyle textStyle(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppTypography.bodyLarge.copyWith(
      color: dark ? AppColors.white : AppColors.inkStrong,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.25,
    );
  }
}

/// Standard professional text field used across Med AI.
class MedAiTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;

  const MedAiTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.textAlign = TextAlign.start,
    this.contentPadding,
    this.style,
  }) : assert(controller == null || initialValue == null);

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? AppInputs.textStyle(context);
    final decoration = AppInputs.decoration(
      context: context,
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
    ).copyWith(
      // Hide the default character counter unless a helper is shown.
      counterText: maxLength != null ? '' : null,
    );

    final Widget field;
    if (controller != null || initialValue == null) {
      field = TextField(
        controller: controller,
        focusNode: focusNode,
        style: style,
        cursorColor: AppColors.limeDeep,
        cursorWidth: 2,
        obscureText: obscureText,
        enabled: enabled,
        autofocus: autofocus,
        readOnly: readOnly,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofillHints: autofillHints,
        textAlign: textAlign,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        decoration: decoration,
      );
    } else {
      field = TextFormField(
        initialValue: initialValue,
        style: style,
        cursorColor: AppColors.limeDeep,
        cursorWidth: 2,
        obscureText: obscureText,
        enabled: enabled,
        autofocus: autofocus,
        readOnly: readOnly,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofillHints: autofillHints,
        textAlign: textAlign,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        onTap: onTap,
        decoration: decoration,
      );
    }

    return Semantics(
      textField: true,
      label: labelText ?? hintText,
      child: field,
    );
  }
}

/// Label above a [MedAiTextField] — settings / forms / onboarding.
class MedAiLabeledField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const MedAiLabeledField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        MedAiTextField(
          controller: controller,
          initialValue: initialValue,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }
}
