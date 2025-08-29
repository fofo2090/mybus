import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// TextField متجاوب مع تخطيط متكيف
class ResponsiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final EdgeInsets? contentPadding;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final InputBorder? errorBorder;
  final Color? fillColor;
  final bool filled;

  const ResponsiveTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.contentPadding,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.fillColor,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveContentPadding = contentPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );

    final responsiveBorderRadius = ResponsiveHelper.getBorderRadius(context);

    final defaultBorder = border ?? OutlineInputBorder(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final defaultFocusedBorder = focusedBorder ?? OutlineInputBorder(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
    );

    final defaultEnabledBorder = enabledBorder ?? OutlineInputBorder(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final defaultErrorBorder = errorBorder ?? OutlineInputBorder(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: ResponsiveHelper.getFontSize(context,
          mobileFontSize: 14,
          tabletFontSize: 16,
          desktopFontSize: 18,
        ),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: responsiveContentPadding,
        border: defaultBorder,
        focusedBorder: defaultFocusedBorder,
        enabledBorder: defaultEnabledBorder,
        errorBorder: defaultErrorBorder,
        fillColor: fillColor ?? Colors.grey.shade50,
        filled: filled,
        labelStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
          ),
        ),
        hintStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
          ),
          color: Colors.grey.shade500,
        ),
        helperStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 10,
            tabletFontSize: 12,
            desktopFontSize: 14,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 10,
            tabletFontSize: 12,
            desktopFontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// DropdownButtonFormField متجاوب
class ResponsiveDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final EdgeInsets? contentPadding;
  final InputBorder? border;
  final Color? fillColor;
  final bool filled;

  const ResponsiveDropdownField({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.contentPadding,
    this.border,
    this.fillColor,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveContentPadding = contentPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );

    final responsiveBorderRadius = ResponsiveHelper.getBorderRadius(context);

    final defaultBorder = border ?? OutlineInputBorder(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: TextStyle(
        fontSize: ResponsiveHelper.getFontSize(context,
          mobileFontSize: 14,
          tabletFontSize: 16,
          desktopFontSize: 18,
        ),
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        contentPadding: responsiveContentPadding,
        border: defaultBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        enabledBorder: defaultBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        fillColor: fillColor ?? Colors.grey.shade50,
        filled: filled,
        labelStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
          ),
        ),
        hintStyle: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
          ),
          color: Colors.grey.shade500,
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        size: ResponsiveHelper.getIconSize(context,
          mobileSize: 20,
          tabletSize: 24,
          desktopSize: 28,
        ),
      ),
    );
  }
}

/// Form متجاوب مع تخطيط متكيف
class ResponsiveForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveForm({
    super.key,
    required this.formKey,
    required this.children,
    this.padding,
    this.spacing,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);
    final responsiveSpacing = spacing ?? ResponsiveHelper.getSpacing(context);

    return Form(
      key: formKey,
      child: Padding(
        padding: responsivePadding,
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: children
              .expand((child) => [child, SizedBox(height: responsiveSpacing)])
              .take(children.length * 2 - 1)
              .toList(),
        ),
      ),
    );
  }
}
