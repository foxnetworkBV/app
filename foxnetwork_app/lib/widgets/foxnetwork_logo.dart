import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FoxNetworkLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool compact;

  const FoxNetworkLogo({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FoxNetworkLogoPainter()),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: compact ? 10 : 14),
        Text(
          'FoxNetwork',
          style: TextStyle(
            fontSize: compact ? 20 : 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _FoxNetworkLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.shortestSide;
    final linePaint = Paint()
      ..color = FoxColors.cyan
      ..strokeWidth = scale * 0.09
      ..strokeCap = StrokeCap.round;
    final nodePaint = Paint()..color = FoxColors.cyan;

    final nodes = <Offset>[
      Offset(center.dx, size.height * 0.14),
      Offset(size.width * 0.82, size.height * 0.42),
      Offset(size.width * 0.70, size.height * 0.80),
      Offset(size.width * 0.30, size.height * 0.80),
      Offset(size.width * 0.18, size.height * 0.42),
    ];

    for (final node in nodes) {
      canvas.drawLine(center, node, linePaint);
    }

    canvas.drawCircle(center, scale * 0.19, nodePaint);
    for (final node in nodes) {
      canvas.drawCircle(node, scale * 0.115, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
