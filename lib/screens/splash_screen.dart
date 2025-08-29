import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../main.dart';
import '../services/persistent_auth_service.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../utils/background_utils.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animated_background.dart';
import '../widgets/responsive_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // زيادة مدة الرسوم المتحركة لـ 3 ثواني
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // منحنى أكثر سلاسة
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.3, // بداية أصغر لتأثير أكثر وضوحاً
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: -150.0, // حركة أكبر
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // انتظار انتهاء الأنيميشن - زيادة الوقت ليشاهد المستخدم الشاشة بوضوح
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      try {
        // الحصول على خدمة المصادقة المستمرة
        final persistentAuthService = Provider.of<PersistentAuthService>(context, listen: false);
        
        // التأكد من تهيئة الخدمة
        await persistentAuthService.initialize();
        
        // فحص حالة المصادقة
        if (persistentAuthService.isAuthenticated && persistentAuthService.currentUserData != null) {
          // المستخدم مسجل دخول - الانتقال حسب نوع المستخدم
          print('✅ User is authenticated: ${persistentAuthService.currentUserData!.name}');
          _navigateBasedOnUserType(persistentAuthService.currentUserData!.userType);
        } else {
          // المستخدم غير مسجل دخول - الانتقال لصفحة تسجيل الدخول
          print('⚠️ User is not authenticated, navigating to login');
          _navigateToLogin();
        }
      } catch (e) {
        print('❌ Error checking auth status: $e');
        // في حالة الخطأ - الانتقال لتسجيل الدخول
        _navigateToLogin();
      }
    }
  }

  void _navigateBasedOnUserType(UserType userType) {
    String route;

    switch (userType) {
      case UserType.parent:
        route = AppRoutes.parentHome;
        break;
      case UserType.supervisor:
        route = AppRoutes.supervisorHome;
        break;
      case UserType.admin:
        route = AppRoutes.adminHome;
        break;
    }

    context.go(route);
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildBusIllustration() {
    return SizedBox(
      width: 320,
      height: 220,
      child: Stack(
        children: [
          // Bus Body - Enhanced
          Positioned(
            left: 20,
            top: 40,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 2 * sin(_animationController.value * 2 * pi)), // Gentle bounce
                  child: Container(
                    width: 260,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD700), // Golden yellow
                          const Color(0xFFFFA500), // Orange
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bus Front
          Positioned(
            left: 240,
            top: 50,
            child: Container(
              width: 30,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          // Bus Windows - Enhanced with more kids
          _buildBusWindow(45, 55, 0), // Driver window
          _buildBusWindow(85, 55, 1), // Window 1
          _buildBusWindow(125, 55, 2), // Window 2
          _buildBusWindow(165, 55, 3), // Window 3
          _buildBusWindow(205, 55, 4), // Window 4
          _buildBusWindow(245, 55, 5), // Window 5

          // Happy kids waving from windows
          _buildWavingKid(95, 45, 1),
          _buildWavingKid(135, 45, 2),
          _buildWavingKid(175, 45, 3),
          _buildWavingKid(215, 45, 4),

          // Bus Wheels
          _buildWheel(50, 130),
          _buildWheel(200, 130),

          // Bus Door
          Positioned(
            left: 35,
            top: 80,
            child: Container(
              width: 25,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

          // Bus Headlight
          Positioned(
            left: 245,
            top: 70,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withAlpha(153),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // School Bus Text
          Positioned(
            left: 90,
            top: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'باص المدرسة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Floating Hearts/Stars around bus - Enhanced
          _buildFloatingIcon(Icons.favorite, Colors.pink, 10, 20, 0.8),
          _buildFloatingIcon(Icons.star, Colors.yellow, 290, 30, 1.2),
          _buildFloatingIcon(Icons.favorite, Colors.red, 15, 180, 1.0),
          _buildFloatingIcon(Icons.star, Colors.orange, 300, 160, 0.9),
          _buildFloatingIcon(Icons.emoji_emotions, Colors.green, 5, 100, 1.1),
          _buildFloatingIcon(Icons.child_friendly, Colors.blue, 295, 90, 0.7),
          _buildFloatingIcon(Icons.school, Colors.purple, 280, 200, 0.8),
          _buildFloatingIcon(Icons.celebration, Colors.cyan, 25, 60, 0.9),

          // Animated balloons
          _buildBalloon(0, 10, Colors.red),
          _buildBalloon(310, 15, Colors.blue),
          _buildBalloon(5, 190, Colors.green),
          _buildBalloon(305, 185, Colors.yellow),
        ],
      ),
    );
  }

  Widget _buildBusWindow(double left, double top, int kidIndex) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 30,
        height: 25,
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB), // Sky blue window
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: kidIndex == 0
          ? const Icon(Icons.person, size: 16, color: Color(0xFF2D3748)) // Driver
          : _buildKidInWindow(kidIndex),
      ),
    );
  }

  Widget _buildKidInWindow(int kidIndex) {
    final kidData = [
      {'color': Colors.brown, 'icon': Icons.boy, 'name': 'أحمد'},
      {'color': Colors.pink, 'icon': Icons.girl, 'name': 'فاطمة'},
      {'color': Colors.purple, 'icon': Icons.child_care, 'name': 'محمد'},
      {'color': Colors.green, 'icon': Icons.face, 'name': 'نور'},
      {'color': Colors.blue, 'icon': Icons.child_friendly, 'name': 'سارة'},
      {'color': Colors.orange, 'icon': Icons.sentiment_very_satisfied, 'name': 'علي'},
    ];

    final kid = kidData[kidIndex % kidData.length];

    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.2 * sin(_animationController.value * 4 * pi + kidIndex)),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    (kid['color'] as Color).withOpacity(0.9),
                    (kid['color'] as Color),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (kid['color'] as Color).withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                kid['icon'] as IconData,
                size: 10,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWavingKid(double left, double top, int kidIndex) {
    final kidColors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange];
    final kidColor = kidColors[kidIndex % kidColors.length];

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: 0.3 * sin(_animationController.value * 6 * pi + kidIndex),
            child: Container(
              width: 8,
              height: 12,
              decoration: BoxDecoration(
                color: kidColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: kidColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.waving_hand,
                size: 6,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheel(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animationController.value * 4 * 3.14159, // Multiple rotations
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(76), // 0.3 * 255 = 76
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, double left, double top, double scale) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              10 * sin(_animationController.value * 2 * pi),
              5 * cos(_animationController.value * 3 * pi),
            ),
            child: Transform.scale(
              scale: scale + (0.3 * sin(_animationController.value * 4 * pi)),
              child: Transform.rotate(
                angle: _animationController.value * 2 * pi,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color.withOpacity(0.9),
                    size: 18,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalloon(double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              5 * sin(_animationController.value * 2 * pi),
              -10 * _animationController.value + 10 * sin(_animationController.value * 4 * pi),
            ),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 15,
                  color: Colors.grey[600],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Circle
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withAlpha(76)),
            strokeWidth: 2,
          ),
        ),
        // Inner Circle
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        // Center Icon
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(229),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 12,
            color: Color(0xFF667EEA),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLoadingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow effect
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Outer Circle with gradient
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              BackgroundUtils.busYellow.withOpacity(0.8),
            ),
            strokeWidth: 4,
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
        ),
        // Middle Circle
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
            backgroundColor: Colors.transparent,
          ),
        ),
        // Inner Circle
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              BackgroundUtils.schoolBlue,
            ),
            strokeWidth: 2,
            backgroundColor: Colors.transparent,
          ),
        ),
        // Center Icon with enhanced styling
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.9),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus,
            size: 18,
            color: BackgroundUtils.busYellow,
          ),
        ),
        // Animated dots around the loading
        ...List.generate(8, (index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final angle = (index * 45.0) + (_animationController.value * 360);
              final radians = angle * (3.14159 / 180);
              final radius = 50.0;

              return Positioned(
                left: radius * cos(radians),
                top: radius * sin(radians),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.3 + (0.7 * ((index + _animationController.value * 8) % 8) / 8),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        showChildren: true,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Top Section with Bus Illustration
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Bus with Kids Illustration
                              Transform.translate(
                                offset: Offset(_slideAnimation.value, 0),
                                child: _buildBusIllustration(),
                              ),
                              const SizedBox(height: 30),

                              // App Name with enhanced styling
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (_scaleAnimation.value * 0.2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'كيدز باص',
                                        style: TextStyle(
                                          fontSize: 52, // زيادة حجم الخط أكثر
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 6, // زيادة المسافة بين الحروف
                                          shadows: [
                                            Shadow(
                                              offset: Offset(4, 4),
                                              blurRadius: 8,
                                              color: Colors.black54,
                                            ),
                                            Shadow(
                                              offset: Offset(-2, -2),
                                              blurRadius: 4,
                                              color: Colors.white38,
                                            ),
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 20,
                                              color: Colors.yellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              // App Subtitle with animation
                              AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.white.withOpacity(0.15),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.4),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'تتبع آمن وسهل لرحلة طفلك المدرسية',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(2, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black38,
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.security,
                                                  color: Colors.white.withOpacity(0.9),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'أمان • سهولة • راحة البال',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.favorite,
                                                  color: Colors.white.withOpacity(0.9),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Section with Loading
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Enhanced Loading Animation
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (0.1 * _animationController.value),
                                  child: _buildEnhancedLoadingAnimation(),
                                );
                              },
                            ),
                            const SizedBox(height: 25),

                            // Enhanced Loading Text with animation
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'جاري التحميل...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 3,
                                                color: Colors.black38,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'نحضر لك تجربة رائعة...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
