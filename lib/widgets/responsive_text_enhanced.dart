import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// نص متجاوب محسن مع دعم أفضل للغة العربية
class ResponsiveTextEnhanced extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final double? largeDesktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final bool autoDirection;
  final bool enableSelection;

  const ResponsiveTextEnhanced(
    this.text, {
    super.key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.largeDesktopFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.autoDirection = true,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = ResponsiveHelper.getFontSize(
      context,
      mobileFontSize: mobileFontSize ?? 14.0,
      tabletFontSize: tabletFontSize ?? 16.0,
      desktopFontSize: desktopFontSize ?? 18.0,
      largeDesktopFontSize: largeDesktopFontSize ?? 20.0,
    );

    // تحديد اتجاه النص تلقائياً للعربية
    TextAlign effectiveTextAlign = textAlign ?? TextAlign.start;
    if (autoDirection && _isArabicText(text)) {
      effectiveTextAlign = textAlign ?? TextAlign.right;
    }

    final textStyle = (style ?? const TextStyle()).copyWith(
      fontSize: responsiveFontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
    );

    Widget textWidget = Text(
      text,
      style: textStyle,
      textAlign: effectiveTextAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: autoDirection && _isArabicText(text) 
        ? TextDirection.rtl 
        : TextDirection.ltr,
    );

    if (enableSelection) {
      textWidget = SelectableText(
        text,
        style: textStyle,
        textAlign: effectiveTextAlign,
        maxLines: maxLines,
        textDirection: autoDirection && _isArabicText(text) 
          ? TextDirection.rtl 
          : TextDirection.ltr,
      );
    }

    return textWidget;
  }

  bool _isArabicText(String text) {
    // فحص بسيط للنص العربي
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

/// عنوان رئيسي متجاوب
class ResponsiveTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveTitle(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 24.0,
      tabletFontSize: 28.0,
      desktopFontSize: 32.0,
      largeDesktopFontSize: 36.0,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.2,
      enableSelection: enableSelection,
    );
  }
}

/// عنوان فرعي متجاوب
class ResponsiveSubtitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveSubtitle(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 18.0,
      tabletFontSize: 20.0,
      desktopFontSize: 22.0,
      largeDesktopFontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.3,
      enableSelection: enableSelection,
    );
  }
}

/// نص عادي متجاوب
class ResponsiveBody extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveBody(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 14.0,
      tabletFontSize: 16.0,
      desktopFontSize: 18.0,
      largeDesktopFontSize: 20.0,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.5,
      enableSelection: enableSelection,
    );
  }
}

/// نص صغير متجاوب
class ResponsiveSmall extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveSmall(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 12.0,
      tabletFontSize: 13.0,
      desktopFontSize: 14.0,
      largeDesktopFontSize: 15.0,
      color: color ?? Theme.of(context).textTheme.bodySmall?.color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.4,
      enableSelection: enableSelection,
    );
  }
}

/// نص للتسميات التوضيحية
class ResponsiveLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveLabel(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 13.0,
      tabletFontSize: 14.0,
      desktopFontSize: 15.0,
      largeDesktopFontSize: 16.0,
      fontWeight: FontWeight.w500,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.4,
      enableSelection: enableSelection,
    );
  }
}

/// نص للأرقام والإحصائيات
class ResponsiveNumber extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableSelection;

  const ResponsiveNumber(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextEnhanced(
      text,
      style: style,
      mobileFontSize: 20.0,
      tabletFontSize: 24.0,
      desktopFontSize: 28.0,
      largeDesktopFontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign ?? TextAlign.center,
      maxLines: maxLines,
      overflow: overflow,
      height: 1.2,
      autoDirection: false, // الأرقام لا تحتاج اتجاه تلقائي
      enableSelection: enableSelection,
    );
  }
}