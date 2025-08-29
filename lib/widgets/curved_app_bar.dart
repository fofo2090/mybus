import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CurvedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final double height;

  const CurvedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF1E88E5);
    final fgColor = foregroundColor ?? Colors.white;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withAlpha(229),
            bgColor.withAlpha(204),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipPath(
        clipper: CurvedBottomClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                bgColor.withAlpha(229), // 0.9 * 255 = 229
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.getPadding(context,
                mobilePadding: const EdgeInsets.symmetric(horizontal: 12),
                tabletPadding: const EdgeInsets.symmetric(horizontal: 16),
                desktopPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                children: [
                  // Leading Widget
                  if (leading != null)
                    leading!
                  else if (automaticallyImplyLeading && Navigator.canPop(context))
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: fgColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  
                  // Title
                  Expanded(
                    child: centerTitle
                        ? Center(
                            child: _buildTitle(fgColor),
                          )
                        : _buildTitle(fgColor),
                  ),
                  
                  // Actions
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

// Custom Clipper للانحناء السفلي
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // البداية من الزاوية اليسرى العلوية
    path.lineTo(0, size.height - 30);

    // إنشاء منحنى سلس في الأسفل
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 15);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height - 30);
    final secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // إكمال المسار إلى الزاوية اليمنى العلوية
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// AppBar منحني مع تأثيرات إضافية ومحسن
class EnhancedCurvedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double height;
  final Widget? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;

  const EnhancedCurvedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.height = 180,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF1E88E5);
    final fgColor = foregroundColor ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: bgColor.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipPath(
        clipper: WaveBottomClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                const Color(0xFF1F1F1F),
                const Color(0xFF2C2C2C),
                const Color(0xFF383838),
              ] : [
                bgColor,
                bgColor.withOpacity(0.9),
                bgColor.withOpacity(0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Leading Widget
                      if (leading != null)
                        Container(
                          decoration: BoxDecoration(
                            color: fgColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: leading!,
                        )
                      else if (leadingIcon != null)
                        Container(
                          decoration: BoxDecoration(
                            color: fgColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(leadingIcon!, color: fgColor, size: 24),
                            onPressed: onLeadingPressed,
                            tooltip: 'القائمة',
                          ),
                        )
                      else if (automaticallyImplyLeading && Navigator.canPop(context))
                        Container(
                          decoration: BoxDecoration(
                            color: fgColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: fgColor, size: 24),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'رجوع',
                          ),
                        ),

                      // Title only (aligned with icons)
                      Expanded(
                        child: centerTitle
                            ? Center(
                                child: _buildTitleOnly(fgColor),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildTitleOnly(fgColor),
                              ),
                      ),

                      // Actions with enhanced styling
                      if (actions != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!.map((action) {
                            return Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: fgColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: action,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  // Subtitle centered below
                  if (subtitle != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: fgColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: fgColor.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          child: subtitle!,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleOnly(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              child: subtitle!,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

// Custom Clipper للموجة
class WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 30);

    // إنشاء موجة بسيطة وجميلة
    final controlPoint1 = Offset(size.width * 0.25, size.height);
    final endPoint1 = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      controlPoint1.dx,
      controlPoint1.dy,
      endPoint1.dx,
      endPoint1.dy,
    );

    final controlPoint2 = Offset(size.width * 0.75, size.height - 40);
    final endPoint2 = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


