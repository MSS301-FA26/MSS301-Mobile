import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A mobile ticket: details above the tear line, stub below it.
class CinemaTicketSurface extends StatelessWidget {
  const CinemaTicketSurface({
    super.key,
    required this.details,
    required this.stub,
    this.borderColor = AppColors.borderStrong,
  });

  final Widget details;
  final Widget stub;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.card,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          details,
          _TicketPerforation(color: borderColor),
          stub,
        ],
      ),
    ),
  );
}

class _TicketPerforation extends StatelessWidget {
  const _TicketPerforation({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 24,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: SizedBox(
            height: 1,
            width: double.infinity,
            child: CustomPaint(painter: _DashPainter(color)),
          ),
        ),
        Positioned(left: -12, top: 0, child: _Notch(color: color)),
        Positioned(right: -12, top: 0, child: _Notch(color: color)),
      ],
    ),
  );
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: AppColors.background,
      shape: BoxShape.circle,
      border: Border.all(color: color),
    ),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 14; x < size.width - 14; x += 10) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 5).clamp(0, size.width - 14), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      color != oldDelegate.color;
}
