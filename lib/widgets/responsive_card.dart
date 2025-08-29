import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Card متجاوب مع تخطيط متكيف
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final bool enableShadow;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.border,
    this.onTap,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);
    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(ResponsiveHelper.getBorderRadius(context));
    final responsiveMargin = margin ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.all(4),
      tabletPadding: const EdgeInsets.all(6),
      desktopPadding: const EdgeInsets.all(8),
    );

    final defaultShadow = enableShadow ? [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: ResponsiveHelper.isMobile(context) ? 4 : 8,
        offset: Offset(0, ResponsiveHelper.isMobile(context) ? 2 : 4),
      ),
    ] : <BoxShadow>[];

    Widget cardContent = Container(
      margin: responsiveMargin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: responsiveBorderRadius,
        boxShadow: boxShadow ?? defaultShadow,
        gradient: gradient,
        border: border,
      ),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: responsiveBorderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Card للإحصائيات مع تخطيط متجاوب
class ResponsiveStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const ResponsiveStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.05),
        ],
      ),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 8,
                    tabletSpacing: 10,
                    desktopSpacing: 12,
                  ),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(context),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveHelper.getIconSize(context,
                    mobileSize: 20,
                    tabletSize: 24,
                    desktopSize: 28,
                  ),
                ),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.7),
                  size: ResponsiveHelper.getIconSize(context,
                    mobileSize: 16,
                    tabletSize: 18,
                    desktopSize: 20,
                  ),
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 24,
                tabletFontSize: 28,
                desktopFontSize: 32,
              ),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) / 2),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 12,
                tabletFontSize: 14,
                desktopFontSize: 16,
              ),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: ResponsiveHelper.getSpacing(context) / 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context,
                  mobileFontSize: 10,
                  tabletFontSize: 12,
                  desktopFontSize: 14,
                ),
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card للإجراءات مع تخطيط متجاوب
class ResponsiveActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;

  const ResponsiveActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.05),
        ],
      ),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 12,
                    tabletSpacing: 14,
                    desktopSpacing: 16,
                  ),
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(context),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveHelper.getIconSize(context,
                    mobileSize: 24,
                    tabletSize: 28,
                    desktopSize: 32,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.7),
                size: ResponsiveHelper.getIconSize(context,
                  mobileSize: 16,
                  tabletSize: 18,
                  desktopSize: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) / 2),
          Text(
            description,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 12,
                tabletFontSize: 14,
                desktopFontSize: 16,
              ),
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Card للطلاب مع تخطيط متجاوب
class ResponsiveStudentCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;

  const ResponsiveStudentCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFFAFBFC),
        ],
      ),
      border: Border.all(
        color: borderColor ?? Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      child: child,
    );
  }
}
