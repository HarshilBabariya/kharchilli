import 'dart:math';

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

/// (base, accent, cut) per outfit. Cuts: 0 tee, 1 collar, 2 hood, 3 jacket, 4 kurta, 5 drape, 6 suit.
const _outfits = <String, (int, int, int)>{
  'outfit_tee': (0xFF3B82F6, 0xFFFFFFFF, 0),
  'outfit_shirt': (0xFFE2E8F0, 0xFF64748B, 1),
  'outfit_polo': (0xFF10B981, 0xFFFFFFFF, 1),
  'outfit_hoodie': (0xFF8B5CF6, 0xFFDDD6FE, 2),
  'outfit_sweater': (0xFFB45309, 0xFFFDE68A, 0),
  'outfit_jersey': (0xFF1D4ED8, 0xFFF97316, 0),
  'outfit_denim': (0xFF3B6BA5, 0xFFE5E7EB, 3),
  'outfit_lab_coat': (0xFFF8FAFC, 0xFF38BDF8, 3),
  'outfit_kurta': (0xFFF59E0B, 0xFF7C2D12, 4),
  'outfit_dress': (0xFFEC4899, 0xFFFBCFE8, 5),
  'outfit_blazer': (0xFF1F2937, 0xFFFFFFFF, 3),
  'outfit_nehru': (0xFF0F766E, 0xFFFDE68A, 4),
  'outfit_leather': (0xFF18181B, 0xFFA1A1AA, 3),
  'outfit_saree': (0xFFBE123C, 0xFFFACC15, 5),
  'outfit_sherwani': (0xFFFEF3C7, 0xFFB45309, 4),
  'outfit_lehenga': (0xFFDB2777, 0xFFFDE047, 5),
  'outfit_spacesuit': (0xFFE5E7EB, 0xFFEF4444, 6),
  'outfit_hero': (0xFFDC2626, 0xFFFACC15, 6),
  'outfit_diwali_silk': (0xFFB4231F, 0xFFF5B301, 4),
  'outfit_holi': (0xFFFFFFFF, 0xFFE91E8C, 4),
  'outfit_garba': (0xFFD9271C, 0xFF16A34A, 4),
  'outfit_kite': (0xFF0284C7, 0xFFFACC15, 0),
  'outfit_rakhi': (0xFFFBCFE8, 0xFFDB2777, 4),
  'outfit_bappa': (0xFFEA580C, 0xFFEAB308, 4),
  'outfit_tiranga': (0xFFF26B0F, 0xFF138808, 3),
  'outfit_santa': (0xFFC62828, 0xFFFFFFFF, 6),
  'outfit_sequin': (0xFF7C3AED, 0xFFF5C451, 3),
};

const _moodExtras = <Mood, String>{Mood.love: '💕', Mood.excited: '✨', Mood.confused: '❓', Mood.sleepy: '💤', Mood.sad: '💧', Mood.worried: '💦', Mood.angry: '💢'};

class AvatarView extends StatefulWidget {
  const AvatarView(this.config, {super.key, this.size = 56, this.animate = false, this.action, this.ring = true});
  final AvatarConfig config;
  final double size;
  final bool animate;

  /// Plays once whenever it changes to a non-null value.
  final AvatarAction? action;
  final bool ring;

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  late final AnimationController _act = AnimationController(vsync: this);
  AvatarAction? _playing;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _idle.repeat();
    _play(widget.action);
  }

  @override
  void didUpdateWidget(AvatarView old) {
    super.didUpdateWidget(old);
    if (widget.action != old.action) _play(widget.action);
  }

  void _play(AvatarAction? action) {
    if (action == null) return;
    _playing = action;
    _act
      ..duration = Duration(milliseconds: action.durationMs)
      ..forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _playing = null);
      });
  }

  @override
  void dispose() {
    _idle.dispose();
    _act.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _act]),
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _AvatarPainter(widget.config, _idle.value, _playing, _act.value, [cs.primary, cs.secondary], widget.ring),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.c, this.idle, this.action, this.t, this.tints, this.ring);
  final AvatarConfig c;
  final double idle;
  final AvatarAction? action;
  final double t;
  final List<Color> tints;
  final bool ring;

  Paint _fill(Color color) => Paint()..color = color;
  Paint _line(Color color, double w) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _emoji(Canvas canvas, String text, Offset at, double size) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final frame = Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawPath(frame, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tints[0].withValues(alpha: 0.28), tints[1].withValues(alpha: 0.34)]).createShader(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.clipPath(frame);

    final wave = sin(idle * 2 * pi);
    final pulse = sin(t * pi);
    var dx = wave * 0.8, dy = 0.0, tilt = wave * 0.012, squashX = 1.0, squashY = 1 + sin(idle * 4 * pi) * 0.008;
    switch (action) {
      case AvatarAction.jump || AvatarAction.cheer:
        dy = -16 * pulse;
        squashY = 1 + 0.06 * sin(t * 2 * pi);
      case AvatarAction.spin:
        squashX = cos(t * 2 * pi);
      case AvatarAction.dance:
        tilt = sin(t * 6 * pi) * 0.12;
        dx = sin(t * 6 * pi) * 5;
      case AvatarAction.wave:
        tilt = sin(t * 4 * pi) * 0.05;
      case AvatarAction.laugh:
        dy = sin(t * 14 * pi) * 1.6;
      default:
        break;
    }
    canvas.translate(50 + dx, 58 + dy);
    canvas.rotate(tilt);
    canvas.scale(squashX.abs() < 0.08 ? 0.08 : squashX, squashY);
    canvas.translate(-50, -58);

    final skin = Color(skinTones[c.skinTone % skinTones.length]);
    final shade = Color.lerp(skin, Colors.black, 0.14)!;
    final hair = Color(hairColors[c.hairColor % hairColors.length]);
    final female = c.gender == Gender.female;
    final head = _headRect();

    _hairBack(canvas, hair, head);
    _body(canvas, skin, shade, female);
    canvas.drawOval(Rect.fromCenter(center: Offset(head.left, 50), width: 7, height: 10), _fill(shade));
    canvas.drawOval(Rect.fromCenter(center: Offset(head.right, 50), width: 7, height: 10), _fill(shade));
    final face = RRect.fromRectAndRadius(head, Radius.elliptical(head.width * _roundness().$1, head.height * _roundness().$2));
    canvas.drawRRect(face, Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.4), radius: 1, colors: [Color.lerp(skin, Colors.white, 0.12)!, skin, shade]).createShader(head));
    _beard(canvas, hair, head);
    _face(canvas, female);
    _hairFront(canvas, hair, head);
    _accessory(canvas, head);
    canvas.restore();

    canvas.save();
    canvas.scale(size.width / 100);
    final extra = _moodExtras[c.mood];
    if (extra != null && action == null) _emoji(canvas, extra, Offset(80, 22 - sin(idle * 2 * pi) * 2), 15);
    if (action == AvatarAction.wave) _emoji(canvas, '👋', Offset(82 + sin(t * 8 * pi) * 3, 52), 20);
    if (action == AvatarAction.cheer) _emoji(canvas, '🙌', Offset(50, 14 - 6 * pulse), 18);
    if (action == AvatarAction.wink) _emoji(canvas, '✨', Offset(74, 40 - 8 * pulse), 12);
    if (ring) canvas.drawCircle(const Offset(50, 50), 48.5, _line(Colors.white.withValues(alpha: 0.75), 3));
    canvas.restore();
  }

  Rect _headRect() {
    switch (c.faceShape) {
      case FaceShape.round:
        return const Rect.fromLTWH(27, 25, 46, 46);
      case FaceShape.square:
        return const Rect.fromLTWH(28, 25, 44, 46);
      case FaceShape.heart:
        return const Rect.fromLTWH(28, 24, 44, 47);
      case FaceShape.long:
        return const Rect.fromLTWH(30, 21, 40, 52);
      case FaceShape.oval:
        return const Rect.fromLTWH(29, 23, 42, 49);
    }
  }

  (double, double) _roundness() => switch (c.faceShape) { FaceShape.square => (0.3, 0.3), FaceShape.heart => (0.5, 0.42), _ => (0.5, 0.5) };

  void _body(Canvas canvas, Color skin, Color shade, bool female) {
    final look = _outfits[c.outfitId] ?? _outfits['outfit_tee']!;
    final base = Color(look.$1), accent = Color(look.$2);
    final w = female ? 30.0 : 34.0;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 62, 14, 16), const Radius.circular(6)), _fill(shade));
    final torso = Path()
      ..moveTo(50 - w, 104)
      ..quadraticBezierTo(50 - w, 76, 50 - 10, 73)
      ..quadraticBezierTo(50, 80, 50 + 10, 73)
      ..quadraticBezierTo(50 + w, 76, 50 + w, 104)
      ..close();
    canvas.drawPath(torso, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(base, Colors.white, 0.12)!, Color.lerp(base, Colors.black, 0.12)!]).createShader(const Rect.fromLTWH(10, 70, 80, 34)));
    switch (look.$3) {
      case 1:
        canvas.drawPath(Path()..moveTo(40, 73)..lineTo(50, 84)..lineTo(44, 88)..close(), _fill(accent));
        canvas.drawPath(Path()..moveTo(60, 73)..lineTo(50, 84)..lineTo(56, 88)..close(), _fill(accent));
      case 2:
        canvas.drawArc(const Rect.fromLTWH(34, 66, 32, 22), 0, pi, false, _line(accent, 4));
        canvas.drawLine(const Offset(46, 86), const Offset(46, 96), _line(accent, 1.4));
        canvas.drawLine(const Offset(54, 86), const Offset(54, 96), _line(accent, 1.4));
      case 3:
        canvas.drawPath(Path()..moveTo(41, 73)..lineTo(50, 100)..lineTo(59, 73)..lineTo(50, 80)..close(), _fill(accent));
        canvas.drawLine(const Offset(41, 73), const Offset(47, 100), _line(Color.lerp(base, Colors.black, 0.3)!, 1.6));
        canvas.drawLine(const Offset(59, 73), const Offset(53, 100), _line(Color.lerp(base, Colors.black, 0.3)!, 1.6));
      case 4:
        canvas.drawLine(const Offset(50, 79), const Offset(50, 100), _line(accent, 2.2));
        for (final y in [84.0, 90.0, 96.0]) {
          canvas.drawCircle(Offset(50, y), 1.3, _fill(Color.lerp(accent, Colors.white, 0.4)!));
        }
        canvas.drawArc(const Rect.fromLTWH(40, 68, 20, 14), 0, pi, false, _line(accent, 2.4));
      case 5:
        canvas.drawPath(Path()..moveTo(24, 100)..quadraticBezierTo(48, 84, 66, 72)..lineTo(72, 76)..quadraticBezierTo(54, 92, 36, 104)..close(), _fill(accent));
      case 6:
        canvas.drawCircle(const Offset(50, 90), 6, _fill(accent));
        canvas.drawCircle(const Offset(50, 90), 3, _fill(base));
        canvas.drawArc(const Rect.fromLTWH(38, 67, 24, 14), 0, pi, false, _line(accent, 3));
      default:
        canvas.drawArc(const Rect.fromLTWH(40, 67, 20, 14), 0, pi, false, _line(Color.lerp(base, Colors.black, 0.25)!, 2));
        if (c.outfitId == 'outfit_jersey') _emoji(canvas, '7', const Offset(50, 92), 9);
    }
  }

  void _hairBack(Canvas canvas, Color hair, Rect head) {
    final p = _fill(Color.lerp(hair, Colors.black, 0.18)!);
    switch (c.hairId) {
      case 'hair_long' || 'hair_braids':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(head.left - 6, head.top + 4, head.right + 6, 88), const Radius.circular(18)), p);
      case 'hair_wavy':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(head.left - 7, head.top + 4, head.right + 7, 80), const Radius.circular(22)), p);
        for (final x in [head.left - 5, head.right + 5]) {
          canvas.drawCircle(Offset(x, 78), 6, p);
        }
      case 'hair_bob':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(head.left - 6, head.top + 2, head.right + 6, 70), const Radius.circular(16)), p);
      case 'hair_afro':
        canvas.drawCircle(Offset(50, head.top + 14), 33, p);
      case 'hair_ponytail':
        canvas.drawOval(Rect.fromLTWH(head.right - 2, head.top + 10, 14, 34), p);
      case 'hair_bun' || 'hair_man_bun':
        canvas.drawCircle(Offset(50, head.top - 4), c.hairId == 'hair_bun' ? 10 : 7, p);
      default:
        break;
    }
  }

  void _hairFront(Canvas canvas, Color hair, Rect head) {
    final p = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(hair, Colors.white, 0.18)!, hair]).createShader(Rect.fromLTWH(head.left - 6, head.top - 12, head.width + 12, 30));
    Path cap(double drop, [double lift = 5]) => Path()
      ..moveTo(head.left - 2, head.top + drop)
      ..quadraticBezierTo(head.left - 4, head.top - lift - 4, 50, head.top - lift)
      ..quadraticBezierTo(head.right + 4, head.top - lift - 4, head.right + 2, head.top + drop)
      ..quadraticBezierTo(head.right - 6, head.top + 6, 50, head.top + 8)
      ..quadraticBezierTo(head.left + 6, head.top + 6, head.left - 2, head.top + drop)
      ..close();
    switch (c.hairId) {
      case 'hair_buzz':
        canvas.drawPath(cap(10, 2), _fill(hair.withValues(alpha: 0.75)));
      case 'hair_curly':
        for (var i = 0; i < 9; i++) {
          final a = pi + i * pi / 8;
          canvas.drawCircle(Offset(50 + cos(a) * (head.width / 2 + 1), head.top + 15 + sin(a) * 17), 7.5, p);
        }
        canvas.drawPath(cap(12), p);
      case 'hair_mohawk':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(44, head.top - 14, 56, head.top + 10), const Radius.circular(6)), p);
      case 'hair_spiky':
        canvas.drawPath(cap(12, 3), p);
        for (var i = 0; i < 5; i++) {
          final x = head.left + 4 + i * (head.width - 8) / 4;
          canvas.drawPath(Path()..moveTo(x - 5, head.top + 3)..lineTo(x, head.top - 12)..lineTo(x + 5, head.top + 3)..close(), p);
        }
      case 'hair_side_part':
        canvas.drawPath(cap(16), p);
        canvas.drawPath(Path()..moveTo(head.left - 2, head.top + 16)..quadraticBezierTo(head.left + 12, head.top + 2, head.right - 6, head.top + 12)..quadraticBezierTo(head.left + 16, head.top + 12, head.left - 2, head.top + 16)..close(), p);
      case 'hair_quiff':
        canvas.drawPath(cap(14), p);
        canvas.drawOval(Rect.fromLTWH(head.left + 6, head.top - 13, head.width - 14, 18), p);
      case 'hair_pixie':
        canvas.drawPath(cap(18), p);
        canvas.drawPath(Path()..moveTo(head.left, head.top + 8)..quadraticBezierTo(50, head.top + 20, head.right - 4, head.top + 6)..lineTo(head.right - 2, head.top)..lineTo(head.left, head.top)..close(), p);
      case 'hair_braids':
        canvas.drawPath(cap(16), p);
        for (final x in [head.left - 4, head.right + 4]) {
          for (var i = 0; i < 5; i++) {
            canvas.drawCircle(Offset(x, 56 + i * 7.0), 4.2, p);
          }
        }
      case 'hair_afro':
        canvas.drawPath(cap(12, 8), p);
      default:
        canvas.drawPath(cap(c.hairId == 'hair_short' ? 14 : 18), p);
    }
  }

  void _beard(Canvas canvas, Color hair, Rect head) {
    if (c.gender == Gender.female) return;
    final p = _fill(hair.withValues(alpha: 0.9));
    final jaw = Path()
      ..moveTo(head.left + 2, 54)
      ..quadraticBezierTo(head.left + 4, head.bottom + 1, 50, head.bottom + 1)
      ..quadraticBezierTo(head.right - 4, head.bottom + 1, head.right - 2, 54)
      ..quadraticBezierTo(head.right - 8, 66, 50, 66)
      ..quadraticBezierTo(head.left + 8, 66, head.left + 2, 54)
      ..close();
    switch (c.beard) {
      case Beard.stubble:
        canvas.drawPath(jaw, _fill(hair.withValues(alpha: 0.28)));
      case Beard.mustache:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 58.5, 16, 3.4), const Radius.circular(2)), p);
      case Beard.goatee:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 58.5, 16, 3), const Radius.circular(2)), p);
        canvas.drawOval(Rect.fromLTWH(45, 65, 10, head.bottom - 63), p);
      case Beard.chinStrap:
        canvas.drawPath(jaw, _line(hair, 3));
      case Beard.full:
        canvas.drawPath(jaw, p);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 58.5, 16, 3.4), const Radius.circular(2)), p);
      case Beard.none:
        break;
    }
  }

  void _face(Canvas canvas, bool female) {
    final mood = c.mood ?? Mood.happy;
    const ink = Color(0xFF2B1B17);
    final blinking = idle > 0.94 && idle < 0.985;
    final laughing = action == AvatarAction.laugh;
    final blush = _fill(const Color(0xFFFF6B8A).withValues(alpha: female ? 0.34 : 0.2));
    canvas.drawOval(const Rect.fromLTWH(33, 53, 9, 5.5), blush);
    canvas.drawOval(const Rect.fromLTWH(58, 53, 9, 5.5), blush);

    final browTilt = switch (mood) { Mood.angry => 2.6, Mood.sad || Mood.worried => -2.2, Mood.smart => -1.0, _ => 0.0 };
    final browW = female ? 1.5 : 2.2;
    canvas.drawLine(Offset(36, 41 - browTilt), Offset(44, 41 + browTilt), _line(ink, browW));
    canvas.drawLine(Offset(56, 41 + browTilt - (mood == Mood.smart ? 2.5 : 0)), Offset(64, 41 - browTilt - (mood == Mood.smart ? 2.5 : 0)), _line(ink, browW));

    for (final x in [40.0, 60.0]) {
      final winking = action == AvatarAction.wink && x == 60.0 && t > 0.2 && t < 0.8;
      if (mood == Mood.love && !blinking) {
        _emoji(canvas, '❤️', Offset(x, 47.5), 7.5);
      } else if (blinking || winking || laughing || mood == Mood.sleepy) {
        canvas.drawArc(Rect.fromCenter(center: Offset(x, 47), width: 7, height: 5), laughing ? pi : 0, pi, false, _line(ink, 1.8));
      } else {
        final open = mood == Mood.excited || mood == Mood.worried ? 4.2 : 3.4;
        canvas.drawCircle(Offset(x, 47.5), open, _fill(ink));
        canvas.drawCircle(Offset(x + 1.1, 46.3), 1.1, _fill(Colors.white));
        if (female) canvas.drawLine(Offset(x + (x < 50 ? -3.4 : 3.4), 45), Offset(x + (x < 50 ? -5.2 : 5.2), 43.4), _line(ink, 1));
      }
    }
    canvas.drawArc(const Rect.fromLTWH(47.5, 50, 5, 5), 0.3, pi - 0.6, false, _line(Colors.black.withValues(alpha: 0.18), 1.2));

    final mouth = _line(const Color(0xFF8C2F39), 2.1);
    if (laughing || mood == Mood.excited || mood == Mood.love) {
      canvas.drawPath(Path()..moveTo(43.5, 59.5)..quadraticBezierTo(50, 69, 56.5, 59.5)..close(), _fill(const Color(0xFF8C2F39)));
      canvas.drawPath(Path()..moveTo(46, 63.6)..quadraticBezierTo(50, 66.6, 54, 63.6)..quadraticBezierTo(50, 62, 46, 63.6)..close(), _fill(const Color(0xFFFF8FA3)));
    } else if (mood == Mood.sad || mood == Mood.angry) {
      canvas.drawArc(const Rect.fromLTWH(44, 60.5, 12, 7), pi, pi, false, mouth);
    } else if (mood == Mood.worried || mood == Mood.confused) {
      canvas.drawPath(Path()..moveTo(44, 62)..quadraticBezierTo(47, 59.5, 50, 62)..quadraticBezierTo(53, 64.5, 56, 62), mouth);
    } else if (mood == Mood.sleepy || mood == Mood.neutral) {
      canvas.drawLine(const Offset(45.5, 62), const Offset(54.5, 62), mouth);
    } else if (mood == Mood.smart) {
      canvas.drawPath(Path()..moveTo(44.5, 61.5)..quadraticBezierTo(51, 64.5, 56.5, 59.5), mouth);
    } else {
      canvas.drawArc(const Rect.fromLTWH(43.5, 55, 13, 9), 0.15, pi - 0.3, false, mouth);
    }
  }

  void _accessory(Canvas canvas, Rect head) {
    const gold = Color(0xFFF5B301);
    switch (c.accessoryId) {
      case 'acc_bindi':
        canvas.drawCircle(const Offset(50, 38.5), 1.7, _fill(const Color(0xFFD60036)));
      case 'acc_earrings':
        canvas.drawCircle(Offset(head.left, 56), 2.2, _fill(gold));
        canvas.drawCircle(Offset(head.right, 56), 2.2, _fill(gold));
      case 'acc_nose_ring':
        canvas.drawCircle(const Offset(47.4, 54.6), 1.6, _line(gold, 0.9));
      case 'acc_glasses' || 'acc_sunglasses':
        final dark = c.accessoryId == 'acc_sunglasses';
        for (final x in [40.0, 60.0]) {
          final lens = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 47.5), width: 13, height: 10), const Radius.circular(4.5));
          if (dark) canvas.drawRRect(lens, _fill(const Color(0xEE101014)));
          canvas.drawRRect(lens, _line(const Color(0xFF1F2937), 1.5));
        }
        canvas.drawLine(const Offset(46.5, 47), const Offset(53.5, 47), _line(const Color(0xFF1F2937), 1.5));
      case 'acc_cap':
        canvas.drawArc(Rect.fromLTRB(head.left - 3, head.top - 9, head.right + 3, head.top + 27), pi, pi, true, _fill(const Color(0xFF2563EB)));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.left + 6, head.top + 7, head.width + 6, 5), const Radius.circular(3)), _fill(const Color(0xFF1E40AF)));
      case 'acc_beanie':
        canvas.drawArc(Rect.fromLTRB(head.left - 3, head.top - 11, head.right + 3, head.top + 29), pi, pi, true, _fill(const Color(0xFFEF4444)));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.left - 4, head.top + 6, head.width + 8, 6.5), const Radius.circular(3)), _fill(const Color(0xFFFCA5A5)));
        canvas.drawCircle(Offset(50, head.top - 11), 4.5, _fill(const Color(0xFFFCA5A5)));
      case 'acc_headphones':
        canvas.drawArc(Rect.fromLTRB(head.left - 3, head.top - 7, head.right + 3, head.top + 50), pi, pi, false, _line(const Color(0xFF111827), 3.4));
        for (final x in [head.left - 2, head.right + 2]) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 49), width: 8, height: 15), const Radius.circular(4)), _fill(const Color(0xFFEF4444)));
        }
      case 'acc_crown':
        final crown = Path()..moveTo(36, head.top + 3);
        for (final pt in [const Offset(35, -11), const Offset(42.5, -3), const Offset(50, -14), const Offset(57.5, -3), const Offset(65, -11), const Offset(64, 3)]) {
          crown.lineTo(pt.dx, head.top + pt.dy);
        }
        canvas.drawPath(crown..close(), _fill(gold));
        canvas.drawCircle(Offset(50, head.top - 3), 2, _fill(const Color(0xFFE11D48)));
      case 'acc_turban':
        canvas.drawOval(Rect.fromLTRB(head.left - 5, head.top - 16, head.right + 5, head.top + 12), _fill(const Color(0xFFEA580C)));
        canvas.drawArc(Rect.fromLTRB(head.left - 2, head.top - 12, head.right + 2, head.top + 14), pi * 1.1, pi * 0.8, false, _line(const Color(0xFFFDBA74), 2));
        canvas.drawCircle(Offset(50, head.top - 3), 2.6, _fill(gold));
      case 'acc_flower':
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(Offset(head.right - 2 + cos(i * 2 * pi / 5) * 3.6, head.top + 12 + sin(i * 2 * pi / 5) * 3.6), 3, _fill(const Color(0xFFF472B6)));
        }
        canvas.drawCircle(Offset(head.right - 2, head.top + 12), 2.2, _fill(gold));
      case 'acc_bow_tie':
        canvas.drawPath(Path()..moveTo(50, 77)..lineTo(42, 72.5)..lineTo(42, 81.5)..close(), _fill(const Color(0xFFBE123C)));
        canvas.drawPath(Path()..moveTo(50, 77)..lineTo(58, 72.5)..lineTo(58, 81.5)..close(), _fill(const Color(0xFFBE123C)));
        canvas.drawCircle(const Offset(50, 77), 2, _fill(const Color(0xFF881337)));
      case 'acc_chain':
        canvas.drawArc(const Rect.fromLTWH(40, 66, 20, 20), 0.2, pi - 0.4, false, _line(gold, 1.8));
        canvas.drawCircle(const Offset(50, 86.5), 2.2, _fill(gold));
      case 'acc_gulal':
        for (final blot in const [(36.0, 55.0, 0xFFE91E8C), (63.0, 52.0, 0xFF00B8D4), (52.0, 34.0, 0xFFFFC400), (44.0, 66.0, 0xFF7C3AED)]) {
          canvas.drawCircle(Offset(blot.$1, blot.$2), 4.2, _fill(Color(blot.$3).withValues(alpha: 0.55)));
        }
      case 'acc_santa_hat' || 'acc_party_hat':
        final santa = c.accessoryId == 'acc_santa_hat';
        final tip = Offset(santa ? head.right + 6 : 50, head.top - (santa ? 14 : 24));
        canvas.drawPath(Path()..moveTo(head.left - 1, head.top + 9)..quadraticBezierTo(50, head.top - 22, tip.dx, tip.dy)..quadraticBezierTo(head.right - 2, head.top - 4, head.right + 1, head.top + 9)..close(), _fill(santa ? const Color(0xFFC62828) : const Color(0xFF7C3AED)));
        if (santa) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.left - 4, head.top + 5, head.width + 8, 7), const Radius.circular(4)), _fill(Colors.white));
        canvas.drawCircle(tip, 4, _fill(santa ? Colors.white : gold));
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => true;
}
