import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Text widget متجاوب يتكيف مع حجم الشاشة
class ResponsiveText extends StatelessWidget {
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

  const ResponsiveText(
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

    final textStyle = (style ?? const TextStyle()).copyWith(
      fontSize: responsiveFontSize,
      fontWeight: fontWeight,
      color: color,
    );

    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Text widget للعناوين الرئيسية
class ResponsiveHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveHeading(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: style,
      mobileFontSize: 20.0,
      tabletFontSize: 24.0,
      desktopFontSize: 28.0,
      largeDesktopFontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Text widget للعناوين الفرعية
class ResponsiveSubheading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveSubheading(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: style,
      mobileFontSize: 16.0,
      tabletFontSize: 18.0,
      desktopFontSize: 20.0,
      largeDesktopFontSize: 22.0,
      fontWeight: FontWeight.w600,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Text widget للنصوص العادية
class ResponsiveBodyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final FontWeight? fontWeight;

  const ResponsiveBodyText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: style?.copyWith(fontWeight: fontWeight) ?? TextStyle(fontWeight: fontWeight),
      mobileFontSize: 14.0,
      tabletFontSize: 15.0,
      desktopFontSize: 16.0,
      largeDesktopFontSize: 17.0,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Text widget للنصوص الصغيرة
class ResponsiveCaption extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveCaption(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: style,
      mobileFontSize: 12.0,
      tabletFontSize: 13.0,
      desktopFontSize: 14.0,
      largeDesktopFontSize: 15.0,
      color: color ?? Colors.grey[600],
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Icon متجاوب
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final double? largeDesktopSize;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.largeDesktopSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveHelper.getIconSize(
      context,
      mobileSize: mobileSize ?? 20.0,
      tabletSize: tabletSize ?? 24.0,
      desktopSize: desktopSize ?? 28.0,
      largeDesktopSize: largeDesktopSize ?? 32.0,
    );

    return Icon(
      icon,
      color: color,
      size: responsiveSize,
    );
  }
}

/// SizedBox متجاوب للمسافات العمودية
class ResponsiveVerticalSpace extends StatelessWidget {
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final double? largeDesktopHeight;

  const ResponsiveVerticalSpace({
    super.key,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.largeDesktopHeight,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getSpacing(
      context,
      mobileSpacing: mobileHeight ?? 8.0,
      tabletSpacing: tabletHeight ?? 12.0,
      desktopSpacing: desktopHeight ?? 16.0,
      largeDesktopSpacing: largeDesktopHeight ?? 20.0,
    );

    return SizedBox(height: height);
  }
}

/// SizedBox متجاوب للمسافات الأفقية
class ResponsiveHorizontalSpace extends StatelessWidget {
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? largeDesktopWidth;

  const ResponsiveHorizontalSpace({
    super.key,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.largeDesktopWidth,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.getSpacing(
      context,
      mobileSpacing: mobileWidth ?? 8.0,
      tabletSpacing: tabletWidth ?? 12.0,
      desktopSpacing: desktopWidth ?? 16.0,
      largeDesktopSpacing: largeDesktopWidth ?? 20.0,
    );

    return SizedBox(width: width);
  }
}
