import 'dart:math' as math;
import 'dart:ui';

import 'package:floatica/res/models/floatica_glass_effect.dart';
import 'package:flutter/material.dart';

/// A reusable container that renders an iOS 26–style Liquid Glass effect.
///
/// This widget encapsulates the full rendering pipeline:
/// 1. Outer shadow
/// 2. Primary blur via [BackdropFilter] with optional saturation boost
/// 3. Tint / gradient layer
/// 4. Multi-layer specular highlight (radial glow, top bar, diagonal streak)
/// 5. Shape-aware edge glow following the border radius
/// 6. Inner shadow for depth (top, bottom, sides)
/// 7. Frosted noise texture (grid-based with jitter)
/// 8. Multi-layer luminosity-aware border
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    required this.glassEffect,
    required this.borderRadius,
    required this.child,
    this.blurScale = 1.0,
  });

  /// The glass effect configuration.
  final FloaticaGlassEffect glassEffect;

  /// The border radius for clipping and decoration.
  final BorderRadius borderRadius;

  /// The child widget to display inside the glass container.
  final Widget child;

  /// Scale factor for the blur sigma (e.g., 0.5 for FAB, 1.0 for nav bar).
  final double blurScale;

  @override
  Widget build(BuildContext context) {
    final sigma = glassEffect.blur * blurScale;

    // Build the image filter — blur + optional saturation
    final ImageFilter filter;
    if (glassEffect.saturationBoost != 1.0) {
      filter = ImageFilter.compose(
        outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        inner: ColorFilter.matrix(
          _saturationMatrix(glassEffect.saturationBoost),
        ),
      );
    } else {
      filter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: glassEffect.enableShadow
            ? [
                BoxShadow(
                  color: glassEffect.shadowColor ??
                      Colors.black.withValues(alpha: 0.25),
                  blurRadius: glassEffect.shadowBlur * blurScale,
                  spreadRadius: glassEffect.shadowSpread * blurScale,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: filter,
          child: CustomPaint(
            painter: _LiquidGlassPainter(
              glassEffect: glassEffect,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Builds a 5×4 color matrix that adjusts saturation.
  static List<double> _saturationMatrix(double saturation) {
    final s = saturation;
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;
    return <double>[
      lumR * (1 - s) + s, lumG * (1 - s), lumB * (1 - s), 0, 0, //
      lumR * (1 - s), lumG * (1 - s) + s, lumB * (1 - s), 0, 0, //
      lumR * (1 - s), lumG * (1 - s), lumB * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// Custom painter that renders the Liquid Glass layers on top of the
/// blurred/saturated backdrop.
///
/// Paint order (back to front):
/// 1. Tint / gradient fill
/// 2. Specular highlights (multi-layer)
/// 3. Edge glow (shape-aware, follows RRect)
/// 4. Inner shadows (four edges)
/// 5. Frosted noise texture (grid-based)
/// 6. Border (luminosity gradient + inner accent)
class _LiquidGlassPainter extends CustomPainter {
  _LiquidGlassPainter({
    required this.glassEffect,
    required this.borderRadius,
  });

  final FloaticaGlassEffect glassEffect;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.resolve(TextDirection.ltr).toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    // Layer 1: Tint / gradient background
    _paintTint(canvas, rect);

    // Layer 2: Multi-layer specular highlights
    if (glassEffect.specularHighlight) {
      _paintSpecularHighlight(canvas, rect);
    }

    // Layer 3: Shape-aware edge glow
    if (glassEffect.edgeGlowIntensity > 0) {
      _paintEdgeGlow(canvas, rect, rrect);
    }

    // Layer 4: Inner shadow for depth
    if (glassEffect.innerShadow) {
      _paintInnerShadow(canvas, rect);
    }

    // Layer 5: Frosted noise texture
    if (glassEffect.noiseOpacity > 0) {
      _paintNoise(canvas, rect);
    }

    // Layer 6: Multi-layer border
    if (glassEffect.borderWidth > 0) {
      _paintBorder(canvas, rrect);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Layer 1: Tint
  // ---------------------------------------------------------------------------

  void _paintTint(Canvas canvas, Rect rect) {
    final paint = Paint();
    if (glassEffect.gradient != null) {
      paint.shader = glassEffect.gradient!.createShader(rect);
    } else {
      paint.color = (glassEffect.tintColor ?? Colors.white)
          .withValues(alpha: glassEffect.opacity);
    }
    canvas.drawRect(rect, paint);
  }

  // ---------------------------------------------------------------------------
  // Layer 2: Specular highlights (multi-layer)
  // ---------------------------------------------------------------------------

  void _paintSpecularHighlight(Canvas canvas, Rect rect) {
    // (A) Radial glow in top-left area — simulates light source
    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.9),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, radialPaint);

    // (B) Top-edge bright bar — lens reflection strip
    final topBarHeight = rect.height * 0.28;
    final topBarRect = Rect.fromLTWH(0, 0, rect.width, topBarHeight);
    final topBarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(topBarRect);
    canvas.drawRect(topBarRect, topBarPaint);

    // (C) Left-edge subtle highlight
    final leftBarWidth = rect.width * 0.15;
    final leftBarRect = Rect.fromLTWH(0, 0, leftBarWidth, rect.height);
    final leftBarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(leftBarRect);
    canvas.drawRect(leftBarRect, leftBarPaint);

    // (D) Diagonal bright streak — refraction simulation
    final streakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: const Alignment(0.3, 0.5),
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.03),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.6],
      ).createShader(rect);
    canvas.drawRect(rect, streakPaint);

    // (E) Bottom-right subtle warm glow — secondary light source
    final warmPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, 1.5),
        radius: 1.2,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, warmPaint);
  }

  // ---------------------------------------------------------------------------
  // Layer 3: Shape-aware edge glow
  // ---------------------------------------------------------------------------

  void _paintEdgeGlow(Canvas canvas, Rect rect, RRect rrect) {
    final intensity = glassEffect.edgeGlowIntensity;

    // (A) Outer edge glow — bright on top, fading to bottom
    const inflate = 0.5;
    final outerGlow = RRect.fromRectAndCorners(
      rect.inflate(inflate),
      topLeft: Radius.circular(rrect.tlRadiusX + inflate),
      topRight: Radius.circular(rrect.trRadiusX + inflate),
      bottomLeft: Radius.circular(rrect.blRadiusX + inflate),
      bottomRight: Radius.circular(rrect.brRadiusX + inflate),
    );

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.50 * intensity),
          Colors.white.withValues(alpha: 0.25 * intensity),
          Colors.white.withValues(alpha: 0.08 * intensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRRect(outerGlow, outerPaint);

    // (B) Inner edge highlight — bright top accent
    const deflate = 0.5;
    final tlR = math.max(0.0, rrect.tlRadiusX - deflate);
    final trR = math.max(0.0, rrect.trRadiusX - deflate);
    final blR = math.max(0.0, rrect.blRadiusX - deflate);
    final brR = math.max(0.0, rrect.brRadiusX - deflate);

    final innerGlow = RRect.fromRectAndCorners(
      rect.deflate(deflate),
      topLeft: Radius.circular(tlR),
      topRight: Radius.circular(trR),
      bottomLeft: Radius.circular(blR),
      bottomRight: Radius.circular(brR),
    );

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.35 * intensity),
          Colors.white.withValues(alpha: 0.12 * intensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.65],
      ).createShader(rect);
    canvas.drawRRect(innerGlow, innerPaint);

    // (C) Top-left corner accent — brightest point of refraction
    final cornerSize = math.min(rect.width, rect.height) * 0.3;
    final cornerRect = Rect.fromLTWH(0, 0, cornerSize, cornerSize);
    final cornerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.25 * intensity),
          Colors.white.withValues(alpha: 0.08 * intensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(cornerRect);
    canvas.drawRect(cornerRect, cornerPaint);
  }

  // ---------------------------------------------------------------------------
  // Layer 4: Inner shadow (four edges)
  // ---------------------------------------------------------------------------

  void _paintInnerShadow(Canvas canvas, Rect rect) {
    // Top inner shadow — simulates glass thickness from top edge
    final topHeight = rect.height * 0.30;
    final topRect = Rect.fromLTWH(0, 0, rect.width, topHeight);
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.09),
          Colors.black.withValues(alpha: 0.03),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(topRect);
    canvas.drawRect(topRect, topPaint);

    // Bottom inner shadow
    final bottomRect = Rect.fromLTWH(
      0,
      rect.height * 0.78,
      rect.width,
      rect.height * 0.22,
    );
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.05),
        ],
      ).createShader(bottomRect);
    canvas.drawRect(bottomRect, bottomPaint);

    // Left inner shadow
    final leftWidth = rect.width * 0.08;
    final leftRect = Rect.fromLTWH(0, 0, leftWidth, rect.height);
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(leftRect);
    canvas.drawRect(leftRect, leftPaint);

    // Right inner shadow
    final rightRect = Rect.fromLTWH(
      rect.width - leftWidth,
      0,
      leftWidth,
      rect.height,
    );
    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(rightRect);
    canvas.drawRect(rightRect, rightPaint);
  }

  // ---------------------------------------------------------------------------
  // Layer 5: Frosted noise texture (grid-based with jitter)
  // ---------------------------------------------------------------------------

  void _paintNoise(Canvas canvas, Rect rect) {
    final random = math.Random(42); // Fixed seed for consistency
    const gridSize = 4.0;

    // Bright noise dots
    final brightPaint = Paint()
      ..color = Colors.white.withValues(alpha: glassEffect.noiseOpacity)
      ..style = PaintingStyle.fill;

    // Dark noise dots (subtle, adds depth)
    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: glassEffect.noiseOpacity * 0.4)
      ..style = PaintingStyle.fill;

    for (double y = 0; y < rect.height; y += gridSize) {
      for (double x = 0; x < rect.width; x += gridSize) {
        // Jitter the position for organic look
        final jx = x + (random.nextDouble() - 0.5) * gridSize * 0.6;
        final jy = y + (random.nextDouble() - 0.5) * gridSize * 0.6;

        // Varying radius for natural texture
        const radius = 0.5;

        // ~65% bright, ~20% dark, ~15% empty — creates frosted look
        final roll = random.nextDouble();
        if (roll < 0.65) {
          canvas.drawCircle(Offset(jx, jy), radius, brightPaint);
        } else if (roll < 0.85) {
          canvas.drawCircle(Offset(jx, jy), radius * 0.8, darkPaint);
        }
        // else: empty space — adds breathing room
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Layer 6: Multi-layer border
  // ---------------------------------------------------------------------------

  void _paintBorder(Canvas canvas, RRect rrect) {
    final borderColor =
        glassEffect.borderColor ?? Colors.white.withValues(alpha: 0.5);

    // (A) Main border — luminosity gradient: brighter top, dimmer bottom
    final mainBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glassEffect.borderWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          borderColor,
          borderColor.withValues(alpha: 0.12),
        ],
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect, mainBorderPaint);

    // (B) Inner border accent — subtle white glow on top half only
    if (rrect.outerRect.height > 12) {
      final innerBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glassEffect.borderWidth * 0.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5],
        ).createShader(rrect.outerRect);

      final deflatedRRect = rrect.deflate(glassEffect.borderWidth);
      canvas.drawRRect(deflatedRRect, innerBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return oldDelegate.glassEffect.blur != glassEffect.blur ||
        oldDelegate.glassEffect.opacity != glassEffect.opacity ||
        oldDelegate.glassEffect.tintColor != glassEffect.tintColor ||
        oldDelegate.glassEffect.gradient != glassEffect.gradient ||
        oldDelegate.glassEffect.borderColor != glassEffect.borderColor ||
        oldDelegate.glassEffect.borderWidth != glassEffect.borderWidth ||
        oldDelegate.glassEffect.enableShadow != glassEffect.enableShadow ||
        oldDelegate.glassEffect.shadowColor != glassEffect.shadowColor ||
        oldDelegate.glassEffect.shadowBlur != glassEffect.shadowBlur ||
        oldDelegate.glassEffect.shadowSpread != glassEffect.shadowSpread ||
        oldDelegate.glassEffect.specularHighlight !=
            glassEffect.specularHighlight ||
        oldDelegate.glassEffect.innerShadow != glassEffect.innerShadow ||
        oldDelegate.glassEffect.saturationBoost !=
            glassEffect.saturationBoost ||
        oldDelegate.glassEffect.noiseOpacity != glassEffect.noiseOpacity ||
        oldDelegate.glassEffect.variant != glassEffect.variant ||
        oldDelegate.glassEffect.edgeGlowIntensity !=
            glassEffect.edgeGlowIntensity ||
        oldDelegate.borderRadius != borderRadius;
  }
}
