import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native Flutter translation of design_preference/splash.html.
/// Digits are decorative animation, never calculated profile values.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});
  final String? error;
  final VoidCallback? onRetry;
  static const background = Color(0xFF130E1B);
  static const gold = Color(0xFFC6A66B);
  static const ink = Color(0xFFF7F3EC);
  static const muted = Color(0xFF9E92AB);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: background,
      ),
      child: Scaffold(
        key: const ValueKey('startup-splash'),
        backgroundColor: background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.3),
              radius: 1,
              colors: [Color(0xFF251833), Color(0xFF160F20), background],
              stops: [0, .6, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ExcludeSemantics(child: Center(child: CustomPaint(size: Size(320, 320), painter: _SplashGeometry()))),
              SafeArea(
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: math.max(0.0, constraints.maxHeight - 96)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: double.infinity, child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle, boxShadow: [BoxShadow(color: gold, blurRadius: 8)])),
                                const SizedBox(width: 8),
                                Flexible(child: Text('KHOA HỌC PYTHAGORAS', style: text.labelMedium?.copyWith(fontSize: 12, letterSpacing: 1.2, color: gold))),
                              ]),
                              Text('№ 01 — KHỞI NGUYÊN', style: text.labelMedium?.copyWith(fontSize: 12, letterSpacing: .6, color: muted)),
                            ],
                          )),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const ExcludeSemantics(child: _SplashEmblem()),
                              const SizedBox(height: 24),
                              Text('PILOGY', style: text.headlineLarge?.copyWith(fontSize: 36, height: 40 / 36, fontWeight: FontWeight.bold, letterSpacing: 3.6, color: ink,
                                shadows: const [Shadow(color: Color(0x40F7F3EC), blurRadius: 24), Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2))])),
                              const SizedBox(height: 8),
                              Text('NUMEROLOGY & SELF-DISCOVERY', textAlign: TextAlign.center, style: text.labelSmall?.copyWith(fontSize: 12, letterSpacing: 3, color: gold)),
                              const SizedBox(height: 16),
                              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: Text('“Khám phá trật tự nội tâm qua tần số rung động của các con số.”', textAlign: TextAlign.center,
                                style: text.titleLarge?.copyWith(fontSize: 16, height: 1.625, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: const Color(0xFFDDD5E3)))),
                              const SizedBox(height: 32),
                              _MatrixTicker(animate: error == null && !MediaQuery.of(context).disableAnimations),
                              const SizedBox(height: 32),
                              if (error == null) ...[
                                const SizedBox(width: 256, child: LinearProgressIndicator(minHeight: 4, color: gold, backgroundColor: Color(0x1AFFFFFF))),
                                const SizedBox(height: 12),
                                Text('Đang mở PILOGY…', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: const Color(0xCCDDD5E3))),
                              ] else ...[
                                Semantics(liveRegion: true, child: Text(error!, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: ink))),
                                const SizedBox(height: 12),
                                TextButton(onPressed: onRetry, style: TextButton.styleFrom(foregroundColor: gold), child: const Text('Thử Lại')),
                              ],
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(children: [
                              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Icon(Icons.verified_user, size: 15, color: gold),
                                const SizedBox(width: 6),
                                Flexible(child: Text('Hồ sơ được lưu an toàn trên thiết bị', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(fontSize: 11, color: const Color(0xFF8E839B)))),
                              ]),
                              const SizedBox(height: 4),
                              Text('PILOGY • CHUẨN MỰC CHIÊM NGHIỆM', textAlign: TextAlign.center, style: text.labelSmall?.copyWith(fontSize: 10, color: const Color(0xFF6E647B))),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatrixTicker extends StatefulWidget {
  const _MatrixTicker({required this.animate});
  final bool animate;
  @override
  State<_MatrixTicker> createState() => _MatrixTickerState();
}

class _MatrixTickerState extends State<_MatrixTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2520));
    if (widget.animate) _controller.repeat();
  }
  @override
  void didUpdateWidget(covariant _MatrixTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * 9).floor().clamp(0, 8);
        return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (var index = 0; index < 9; index++) Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == active ? const Color(0x38C6A66B) : const Color(0x0AFFFFFF),
              border: Border.all(color: index == active ? SplashScreen.gold : const Color(0x1AFFFFFF)),
              boxShadow: index == active ? const [BoxShadow(color: Color(0x80C6A66B), blurRadius: 12)] : null,
            ),
            child: Text('${index + 1}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: index == active ? SplashScreen.ink : SplashScreen.muted)),
          ),
        ]);
      },
    ),
  );
}

class _SplashEmblem extends StatelessWidget {
  const _SplashEmblem();
  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(colors: [Color(0xEB2E1F3A), Color(0xF2160F1F)]),
      border: Border.all(color: const Color(0x66C6A66B)),
      boxShadow: const [BoxShadow(color: Color(0x33C6A66B), blurRadius: 30)],
    ),
    child: Stack(clipBehavior: Clip.none, children: [
      const Center(child: CustomPaint(size: Size(80, 80), painter: _SplashGeometry(emblem: true))),
      for (final item in const [(text: '1', alignment: Alignment(0, -1.12)), (text: '5', alignment: Alignment(1.12, 0)), (text: '9', alignment: Alignment(0, 1.12))])
        Align(alignment: item.alignment, child: Text(item.text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFDFC085)))),
    ]),
  );
}

class _SplashGeometry extends CustomPainter {
  const _SplashGeometry({this.emblem = false});
  final bool emblem;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / (emblem ? 100 : 200);
    canvas.save();
    canvas.translate((size.width - size.shortestSide) / 2, (size.height - size.shortestSide) / 2);
    canvas.scale(scale);
    final center = emblem ? const Offset(50, 50) : const Offset(100, 100);
    final paint = Paint()..style = PaintingStyle.stroke..color = SplashScreen.gold.withOpacity(emblem ? .65 : .25)..strokeWidth = emblem ? 1 : .75;
    if (emblem) {
      canvas.drawCircle(center, 45, paint);
      _dashedCircle(canvas, center, 38, paint, 3, 3);
    } else {
      _dashedCircle(canvas, center, 94, paint, 2, 3);
      canvas.drawCircle(center, 78, paint);
      _dashedCircle(canvas, center, 52, paint, 1, 2);
      _dashedLine(canvas, const Offset(6, 100), const Offset(194, 100), paint);
      _dashedLine(canvas, const Offset(100, 6), const Offset(100, 194), paint);
    }
    final points = emblem
        ? const [Offset(50,16), Offset(58,38), Offset(81,38), Offset(62,52), Offset(69,74), Offset(50,60), Offset(31,74), Offset(38,52), Offset(19,38), Offset(42,38)]
        : const [Offset(100,22), Offset(118,76), Offset(174,76), Offset(129,108), Offset(146,162), Offset(100,129), Offset(54,162), Offset(71,108), Offset(26,76), Offset(82,76)];
    final star = Path()..addPolygon(points, true);
    if (emblem) canvas.drawPath(star, Paint()..color = const Color(0x33C6A66B));
    paint.color = const Color(0xFFDFC085).withOpacity(emblem ? 1 : .25);
    paint.strokeWidth = emblem ? 1.2 : .6;
    paint.strokeJoin = StrokeJoin.round;
    canvas.drawPath(star, paint);
    if (emblem) canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFFDFC085));
    canvas.restore();
  }
  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint, double dash, double gap) {
    for (var offset = 0.0; offset < math.pi * 2 * radius; offset += dash + gap) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), offset / radius, dash / radius, false, paint);
    }
  }
  void _dashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final length = (end - start).distance;
    final unit = (end - start) / length;
    for (var offset = 0.0; offset < length; offset += 10) {
      canvas.drawLine(start + unit * offset, start + unit * math.min(offset + 4, length), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _SplashGeometry oldDelegate) => oldDelegate.emblem != emblem;
}
