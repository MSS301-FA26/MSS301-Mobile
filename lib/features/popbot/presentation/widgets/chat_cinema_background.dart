import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Static, decorative scenery that never intercepts chat gestures.
class ChatCinemaBackground extends StatelessWidget {
  const ChatCinemaBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(painter: _CinemaPainter()),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _CinemaPainter extends CustomPainter {
  const _CinemaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF08060E));
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.65),
          radius: 1.05,
          colors: [Color(0xFF2B1244), Color(0x00140B20)],
        ).createShader(bounds),
    );

    // A wide screen and a soft projector beam recede behind the conversation.
    final screen = Path()
      ..moveTo(size.width * .12, 42)
      ..quadraticBezierTo(size.width * .5, 16, size.width * .88, 42);
    canvas.drawPath(
      screen,
      Paint()
        ..color = AppColors.lavender.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final beam = Path()
      ..moveTo(size.width * .16, 43)
      ..lineTo(size.width * .84, 43)
      ..lineTo(size.width * .97, size.height * .58)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .68,
        size.width * .03,
        size.height * .58,
      )
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0ECA9AF5), Color(0x00CA9AF5)],
        ).createShader(bounds),
    );

    // Rows of cinema seats stay in the lower half, away from the welcome copy.
    for (var row = 0; row < 4; row++) {
      final seatWidth = size.width / (8 - row * .5);
      final baseline = size.height * .68 + row * 52;
      final paint = Paint()
        ..color = AppColors.lavender.withValues(alpha: .055 + row * .012)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (var column = -1; column < 9; column++) {
        final x = column * seatWidth + (row.isOdd ? seatWidth / 2 : 0);
        final curve = (x / size.width - .5).abs() * 26;
        final seat = Rect.fromLTWH(x + 6, baseline + curve, seatWidth - 12, 30);
        canvas.drawRRect(
          RRect.fromRectAndRadius(seat, const Radius.circular(9)),
          paint,
        );
        canvas.drawLine(
          Offset(seat.left - 3, seat.top + 16),
          Offset(seat.left - 3, seat.bottom + 5),
          paint,
        );
        canvas.drawLine(
          Offset(seat.right + 3, seat.top + 16),
          Offset(seat.right + 3, seat.bottom + 5),
          paint,
        );
        canvas.drawLine(
          Offset(seat.left, seat.bottom + 5),
          Offset(seat.right, seat.bottom + 5),
          paint,
        );
      }
    }
    // Fade scenery underneath the composer instead of ending in a hard edge.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .7, 1],
          colors: [Colors.transparent, Colors.transparent, Color(0xFF08060E)],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _CinemaPainter oldDelegate) => false;
}
