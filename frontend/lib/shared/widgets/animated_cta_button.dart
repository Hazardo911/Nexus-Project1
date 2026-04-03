import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AnimatedCtaButton extends StatefulWidget {
  const AnimatedCtaButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors = AppColors.heroGradient,
    this.textColor = AppColors.white,
    this.height = 62,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color> colors;
  final Color textColor;
  final double height;

  @override
  State<AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<AnimatedCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_pressed ? 24 : 30),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withValues(alpha: _pressed ? 0.22 : 0.34),
                blurRadius: _pressed ? 18 : 28,
                spreadRadius: _pressed ? 0 : 1,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: widget.colors.last.withValues(alpha: _pressed ? 0.08 : 0.18),
                blurRadius: _pressed ? 24 : 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_pressed ? 24 : 30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 + math.sin(t * math.pi * 2) * 0.22, -0.9),
                          end: Alignment(1 - math.cos(t * math.pi * 2) * 0.18, 0.9),
                          colors: [
                            Color.lerp(widget.colors.first, widget.colors.last, 0.18)!,
                            widget.colors.first,
                            Color.lerp(widget.colors.last, widget.colors.first, 0.28)!,
                            widget.colors.last,
                          ],
                          stops: const [0.0, 0.26, 0.7, 1.0],
                        ),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final t = _controller.value;
                      return Stack(
                        children: [
                          Positioned(
                            left: 18 + (math.sin(t * math.pi * 2) * 18),
                            top: 10 + (math.cos(t * math.pi * 2) * 8),
                            child: _GlowOrb(
                              size: 92,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Positioned(
                            right: 20 + (math.cos(t * math.pi * 2) * 14),
                            bottom: 6 + (math.sin(t * math.pi * 2) * 6),
                            child: _GlowOrb(
                              size: 110,
                              color: widget.colors.last.withValues(alpha: 0.22),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                                borderRadius: BorderRadius.circular(_pressed ? 24 : 30),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final pulse = 0.92 + (math.sin(_controller.value * math.pi * 2) * 0.06);
                        return Transform.scale(
                          scale: pulse,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_pressed ? 24 : 30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Center(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: _pressed ? const Offset(0.01, 0.02) : Offset.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          _AnimatedIconBadge(
                            icon: widget.icon!,
                            color: widget.textColor,
                            controller: _controller,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: widget.textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedIconBadge extends StatelessWidget {
  const _AnimatedIconBadge({
    required this.icon,
    required this.color,
    required this.controller,
  });

  final IconData icon;
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final wave = 1 + (math.sin(controller.value * math.pi * 2) * 0.05);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: wave,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
              ),
            ),
            Icon(icon, color: color),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.45),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
