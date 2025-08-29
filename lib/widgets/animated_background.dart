import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showChildren;
  
  const AnimatedBackground({
    super.key,
    required this.child,
    this.showChildren = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatingController;
  late Animation<double> _animation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation for gradient movement
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Animation for floating elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF1E88E5),
                  const Color(0xFF42A5F5),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFF42A5F5),
                  const Color(0xFF64B5F6),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFF64B5F6),
                  const Color(0xFF90CAF9),
                  _animation.value,
                )!,
              ],
              stops: [
                0.0 + (_animation.value * 0.2),
                0.5 + (_animation.value * 0.3),
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Floating clouds
              if (widget.showChildren) ..._buildFloatingClouds(),
              
              // School bus animation
              if (widget.showChildren) _buildSchoolBus(),
              
              // Children silhouettes
              if (widget.showChildren) ..._buildChildrenSilhouettes(),
              
              // Floating shapes
              if (widget.showChildren) ..._buildFloatingShapes(),
              
              // Main content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingClouds() {
    return [
      Positioned(
        top: 50,
        left: 20,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_floatingAnimation.value, _floatingAnimation.value * 0.5),
              child: Opacity(
                opacity: 0.3,
                child: Icon(
                  Icons.cloud,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 80,
        right: 40,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-_floatingAnimation.value * 0.8, _floatingAnimation.value),
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.cloud,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildSchoolBus() {
    return Positioned(
      bottom: 100,
      left: -50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              (MediaQuery.of(context).size.width + 100) * _animation.value - 50,
              math.sin(_animation.value * math.pi * 2) * 5,
            ),
            child: Opacity(
              opacity: 0.4,
              child: Icon(
                Icons.directions_bus,
                size: 50,
                color: Colors.yellow[700],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildChildrenSilhouettes() {
    return [
      Positioned(
        bottom: 20,
        left: 30,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.3),
              child: Opacity(
                opacity: 0.2,
                child: Column(
                  children: [
                    Icon(
                      Icons.child_care,
                      size: 40,
                      color: Colors.white,
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 30,
        right: 50,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatingAnimation.value * 0.4),
              child: Opacity(
                opacity: 0.25,
                child: Column(
                  children: [
                    Icon(
                      Icons.child_friendly,
                      size: 35,
                      color: Colors.white,
                    ),
                    Container(
                      width: 2,
                      height: 18,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 25,
        left: MediaQuery.of(context).size.width * 0.6,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.2),
              child: Opacity(
                opacity: 0.2,
                child: Column(
                  children: [
                    Icon(
                      Icons.face,
                      size: 30,
                      color: Colors.white,
                    ),
                    Container(
                      width: 2,
                      height: 15,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildFloatingShapes() {
    return [
      Positioned(
        top: 150,
        right: 20,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * math.pi * 2,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.star,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 200,
        left: 50,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_animation.value * math.pi * 2,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.favorite,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
