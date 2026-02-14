import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WalkingLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const WalkingLoader({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  State<WalkingLoader> createState() => _WalkingLoaderState();
}

class _WalkingLoaderState extends State<WalkingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WalkingPersonPainter(
            animationValue: _controller.value,
            color: widget.color ?? (AppColors.primary),
          ),
        );
      },
    );
  }
}

class _WalkingPersonPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WalkingPersonPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08 // Slightly thicker for visibility
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Center of the canvas
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Time cycle (0 to 1) -> Angle (0 to 2PI)
    final t = animationValue * 2 * math.pi;

    // Body dimensions 
    // We want the figure to be mostly centered.
    // Stick Figure height ~ 70% of canvas
    final totalHeight = size.height * 0.7;
    final headRadius = totalHeight * 0.12;
    final torsoLength = totalHeight * 0.35;
    final limbLength = totalHeight * 0.35;

    // Body bobbing (vertical movement)
    // Lowest height (max bob) at max leg spread (PI/2, 3PI/2).
    // Highest height (min bob) at mid-stance (0, PI).
    // -cos(2t) is -1 at 0 (High), 1 at PI/2 (Low).
    final bobY = -math.cos(t * 2) * (totalHeight * 0.05).abs();
    
    // Torso Position
    // Top of torso (Neck)
    final neckY = (cy - totalHeight * 0.2) + bobY;
    final neck = Offset(cx, neckY);
    // Bottom of torso (Hips)
    final hipY = neckY + torsoLength;
    final hip = Offset(cx, hipY);

    // HEAD
    // Head floats just above neck
    canvas.drawCircle(Offset(cx, neckY - headRadius - (size.height * 0.02)), headRadius, headPaint);

    // DRAW TORSO
    // Slightly lean forward? For walking, maybe small lean.
    // Let's keep it straight vertical for simplicity or add lean later.
    final lean = math.sin(t) * 2; // small sway?
    canvas.drawLine(neck, hip, paint);

    // LEGS
    // We need 2 segments: Thigh + Shin
    // Hip Angle oscillates.
    // Left Leg
    _drawLeg(canvas, paint, hip, t, limbLength, isLeft: true);
    // Right Leg (Phase shifted by PI)
    _drawLeg(canvas, paint, hip, t + math.pi, limbLength, isLeft: false);

    // Draw Road
    final roadPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final roadY = size.height * 0.9;
    
    // Moving road dashes
    // We want them to move LEFT as person walks RIGHT.
    // Offset = -animationValue * period
    final dashWidth = size.width * 0.15;
    final gapWidth = size.width * 0.1;
    final totalDash = dashWidth + gapWidth;
    
    // Calculate scroll offset
    final scroll = (1.0 - animationValue) * totalDash; 
    
    // Draw dashes covering the width
    for (double i = -totalDash; i < size.width + totalDash; i += totalDash) {
      final start = i + scroll;
      if (start + dashWidth > 0 && start < size.width) {
         canvas.drawLine(
           Offset(start, roadY), 
           Offset(start + dashWidth, roadY), 
           roadPaint
         );
      }
    }

    // ARMS
    // Arms swing opposite to legs.
    // Shoulder (slightly down from neck)
    final shoulderY = neckY + (torsoLength * 0.2);
    final shoulder = Offset(cx, shoulderY);
    
    // Left Arm (Opposite to Left Leg)
    _drawArm(canvas, paint, shoulder, t + math.pi, limbLength * 0.8, isLeft: true);
    // Right Arm (Opposite to Right Leg)
    _drawArm(canvas, paint, shoulder, t, limbLength * 0.8, isLeft: false);
  }

  void _drawLeg(Canvas canvas, Paint paint, Offset hip, double cycle, double length, {required bool isLeft}) {
    // Simple Walk Cycle logic
    // Thigh Angle: Sine wave
    // Knee Angle: Bends only when moving forward (lifting leg)
    
    // Clean sine for thigh swing (-0.5 to 0.5 rad approx)
    final swing = math.sin(cycle) * 0.6;
    
    // KNEE BEND
    // When moving forward (swing > 0?), we lift the foot -> bend knee.
    // When planting/moving back (swing < 0?), leg is straighter.
    // Let's use a simplified version:
    // Bend = mostly based on lifting phase.
    // Let's say leg lifts when swing is increasing.
    // A simple approach is adding a sine component for the knee.
    
    // Absolute simplification: Just straight swinging legs looks like marching.
    // Let's do a 2-segment leg.
    
    // Move hip joint slightly for realism? No, keep it simple.
    
    final kneeX = hip.dx + math.sin(swing) * length;
    final kneeY = hip.dy + math.cos(swing) * length;
    final knee = Offset(kneeX, kneeY);

    canvas.drawLine(hip, knee, paint);

    // Shin (Lower Leg)
    // We want the knee to bend during the FORWARD SWING (when the leg is in the air).
    // Forward swing is roughly centered at cycle = 0 (or 2PI).
    // cosine is positive at 0.
    // So we use cosine to determine the bend amount.
    final shinAngleOffset = math.max(0.0, math.cos(cycle) * 1.5); 
    // We subtract the offset to bend the foot 'back' (Left) relative to the forward (Right) movement.
    final footX = kneeX + math.sin(swing - shinAngleOffset) * length;
    final footY = kneeY + math.cos(swing - shinAngleOffset) * length;
    final foot = Offset(footX, footY);

    canvas.drawLine(knee, foot, paint);
  }

  void _drawArm(Canvas canvas, Paint paint, Offset shoulder, double cycle, double length, {required bool isLeft}) {
    // Arm swing
    final swing = math.sin(cycle) * 0.5;
    
    // Elbow? Maybe just straight arms swinging for cartoon look.
    // Or slightly bent.
    
    final handX = shoulder.dx + math.sin(swing) * length;
    final handY = shoulder.dy + math.cos(swing) * length;
    final hand = Offset(handX, handY);
    
    canvas.drawLine(shoulder, hand, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
