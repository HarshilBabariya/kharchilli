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
  'outfit_tracksuit': (0xFF111827, 0xFF22D3EE, 2),
  'outfit_raincoat': (0xFFFACC15, 0xFF1F2937, 2),
  'outfit_pathani': (0xFF334155, 0xFFE2E8F0, 4),
  'outfit_anarkali': (0xFF0D9488, 0xFFFDE68A, 5),
  'outfit_bandhgala': (0xFF7F1D1D, 0xFFF5B301, 4),
  'outfit_gown': (0xFF6D28D9, 0xFFE9D5FF, 5),
  'outfit_tuxedo': (0xFF0B0B0F, 0xFFFFFFFF, 3),
  'outfit_pilot': (0xFF1E3A8A, 0xFFFACC15, 6),
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

class AvatarView extends StatefulWidget {
  const AvatarView(this.config, {super.key, this.size = 56, this.animate = false, this.action, this.ring = true, this.full = false});
  final AvatarConfig config;
  final double size;
  final bool animate;

  /// Plays once whenever it changes to a non-null value.
  final AvatarAction? action;
  final bool ring;

  /// Draws the whole standing figure, [size] wide and 1.9 times as tall, instead of the round portrait.
  final bool full;

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
        size: Size(widget.size, widget.full ? widget.size * 1.9 : widget.size),
        painter: _AvatarPainter(widget.config, _idle.value, _playing, _act.value, [cs.primary, cs.secondary], widget.ring, widget.full),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.c, this.idle, this.action, this.t, this.tints, this.ring, this.full);
  final AvatarConfig c;
  final double idle;
  final AvatarAction? action;
  final double t;
  final List<Color> tints;
  final bool ring;
  final bool full;

  static const _head = Rect.fromLTRB(30, 20, 70, 68);
  static const _ink = Color(0xFF2B1B17);

  Paint _fill(Color color) => Paint()..color = color;
  Paint _line(Color color, double w) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: size, color: color)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _heart(Canvas canvas, Offset o, double s, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + s * 0.9)
        ..cubicTo(o.dx - s * 1.4, o.dy - s * 0.1, o.dx - s * 0.6, o.dy - s * 1.1, o.dx, o.dy - s * 0.3)
        ..cubicTo(o.dx + s * 0.6, o.dy - s * 1.1, o.dx + s * 1.4, o.dy - s * 0.1, o.dx, o.dy + s * 0.9)
        ..close(),
      _fill(color),
    );
  }

  void _sparkle(Canvas canvas, Offset o, double s, Color color) {
    final path = Path()..moveTo(o.dx, o.dy - s);
    for (final p in [Offset(s * 0.25, -s * 0.25), Offset(s, 0), Offset(s * 0.25, s * 0.25), Offset(0, s), Offset(-s * 0.25, s * 0.25), Offset(-s, 0), Offset(-s * 0.25, -s * 0.25)]) {
      path.lineTo(o.dx + p.dx, o.dy + p.dy);
    }
    canvas.drawPath(path..close(), _fill(color));
  }

  void _drop(Canvas canvas, Offset o, double s) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - s * 1.3)
        ..quadraticBezierTo(o.dx + s * 1.1, o.dy + s * 0.2, o.dx, o.dy + s)
        ..quadraticBezierTo(o.dx - s * 1.1, o.dy + s * 0.2, o.dx, o.dy - s * 1.3)
        ..close(),
      _fill(const Color(0xFF5BB8FF)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (full) {
      _paintFull(canvas, size);
      return;
    }
    canvas.save();
    canvas.scale(size.width / 100);
    final frame = Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawPath(frame, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(tints[0], Colors.white, 0.62)!, Color.lerp(tints[1], Colors.white, 0.38)!]).createShader(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.clipPath(frame);
    canvas.drawCircle(const Offset(50, 98), 46, _fill(Colors.white.withValues(alpha: 0.3)));

    final wave = sin(idle * 2 * pi);
    final pulse = sin(t * pi);
    var dx = wave * 0.7, dy = 0.0, tilt = wave * 0.012, squashX = 1.0, squashY = 1 + sin(idle * 4 * pi) * 0.008;
    switch (action) {
      case AvatarAction.jump || AvatarAction.cheer:
        dy = -14 * pulse;
        squashY = 1 + 0.06 * sin(t * 2 * pi);
      case AvatarAction.spin:
        squashX = cos(t * 2 * pi);
      case AvatarAction.dance:
        tilt = sin(t * 6 * pi) * 0.11;
        dx = sin(t * 6 * pi) * 5;
      case AvatarAction.wave:
        tilt = sin(t * 4 * pi) * 0.04;
      case AvatarAction.laugh:
        dy = sin(t * 14 * pi) * 1.5;
      default:
        break;
    }
    canvas.translate(50 + dx, 60 + dy);
    canvas.rotate(tilt);
    canvas.scale(squashX.abs() < 0.08 ? 0.08 : squashX, squashY);
    canvas.translate(-50, -60);

    final skin = Color(skinTones[c.skinTone % skinTones.length]);
    final shade = Color.lerp(skin, const Color(0xFF7A3E12), 0.2)!;
    final hair = Color(hairColors[c.hairColor % hairColors.length]);
    final female = c.gender == Gender.female;

    _hairBack(canvas, hair);
    _body(canvas, shade);
    canvas.drawOval(const Rect.fromLTWH(25.9, 42, 7.2, 10), _fill(shade));
    canvas.drawOval(const Rect.fromLTWH(66.9, 42, 7.2, 10), _fill(shade));
    final face = _face();
    canvas.drawPath(face, Paint()..shader = RadialGradient(center: const Alignment(-0.25, -0.4), radius: 0.95, colors: [Color.lerp(skin, Colors.white, 0.2)!, skin, shade], stops: const [0, 0.62, 1]).createShader(_head));
    _beard(canvas, hair);
    _features(canvas, female);
    _hairFront(canvas, hair);
    _accessory(canvas, _head);
    canvas.restore();

    canvas.save();
    canvas.scale(size.width / 100);
    if (action == null) _moodExtra(canvas);
    if (action == AvatarAction.wave) {
      canvas.save();
      canvas.translate(82, 62);
      canvas.rotate(-0.3 + sin(t * 8 * pi) * 0.35);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -16, 14, 17), const Radius.circular(6.5)), _fill(skin));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -16, 14, 17), const Radius.circular(6.5)), _line(shade, 1));
      canvas.drawLine(const Offset(-2.4, -13), const Offset(-2.4, -8), _line(shade, 0.9));
      canvas.drawLine(const Offset(2.4, -13), const Offset(2.4, -8), _line(shade, 0.9));
      canvas.restore();
    }
    if (action == AvatarAction.cheer) {
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4 + t;
        _sparkle(canvas, Offset(50 + cos(a) * 40 * pulse, 30 + sin(a) * 24 * pulse), 2.6, [const Color(0xFFFFC531), const Color(0xFF2EC4B6), const Color(0xFFFF6FB5)][i % 3]);
      }
    }
    if (action == AvatarAction.wink) _sparkle(canvas, Offset(76, 40 - 8 * pulse), 4 * pulse + 1, const Color(0xFFFFC531));
    if (ring) canvas.drawCircle(const Offset(50, 50), 48.5, _line(Colors.white.withValues(alpha: 0.85), 3));
    canvas.restore();
  }

  /// The standing figure on a 100 x 190 canvas: legs, arms and a full-length outfit under the portrait's own head.
  void _paintFull(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    canvas.translate(0, 12);
    final pulse = sin(t * pi);
    var dy = sin(idle * 2 * pi) * 0.6, tilt = 0.0, squashX = 1.0;
    switch (action) {
      case AvatarAction.jump || AvatarAction.cheer:
        dy -= 14 * pulse;
      case AvatarAction.spin:
        squashX = cos(t * 2 * pi);
      case AvatarAction.dance:
        tilt = sin(t * 6 * pi) * 0.08;
      case AvatarAction.laugh:
        dy += sin(t * 14 * pi) * 1.2;
      default:
        break;
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 171), width: 52 - dy.abs(), height: 10), _fill(Colors.black.withValues(alpha: 0.12)));
    canvas.translate(50, 168 + dy);
    canvas.rotate(tilt);
    canvas.scale(squashX.abs() < 0.08 ? 0.08 : squashX, 1);
    canvas.translate(-50, -168);

    final skin = Color(skinTones[c.skinTone % skinTones.length]);
    final shade = Color.lerp(skin, const Color(0xFF7A3E12), 0.2)!;
    final hair = Color(hairColors[c.hairColor % hairColors.length]);
    final look = _outfits[c.outfitId] ?? _outfits['outfit_tee']!;
    final base = Color(look.$1), accent = Color(look.$2), cut = look.$3;
    final deep = Color.lerp(base, Colors.black, 0.3)!;
    void onHead(VoidCallback draw) {
      canvas.save();
      canvas.translate(50, 0);
      canvas.scale(0.94);
      canvas.translate(-50, -11);
      draw();
      canvas.restore();
    }

    onHead(() => _hairBack(canvas, hair));

    final shoe = _fill(cut == 4 ? const Color(0xFF8A5A2B) : const Color(0xFF1F2430));
    if (cut == 5) {
      for (final x in [41.0, 52.0]) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 140, 7, 24), const Radius.circular(3.5)), _fill(skin));
      }
    } else {
      final pants = switch (cut) { 1 => const Color(0xFF3B3F4A), 3 => const Color(0xFF22252E), 4 => const Color(0xFFF3EBDD), 6 => base, _ => const Color(0xFF2B3A67) };
      canvas.drawPath(Path()..moveTo(37, 104)..lineTo(63, 104)..lineTo(61, 162)..lineTo(52, 162)..lineTo(50, 122)..lineTo(48, 162)..lineTo(39, 162)..close(), _fill(pants));
    }
    for (final x in [35.0, 51.0]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 160, 14, 8), const Radius.circular(4)), shoe);
    }

    final waving = action == AvatarAction.wave || action == AvatarAction.cheer;
    final swing = waving ? sin(t * 8 * pi) * 4 : 0.0;
    canvas.drawPath(Path()..moveTo(35, 62)..quadraticBezierTo(27, 66, 26, 96), _line(base, 9));
    canvas.drawCircle(const Offset(26, 100), 4.6, _fill(skin));
    if (waving) {
      canvas.drawPath(Path()..moveTo(65, 62)..quadraticBezierTo(76, 58, 80 + swing, 38), _line(base, 9));
      canvas.drawCircle(Offset(80.5 + swing, 34), 4.6, _fill(skin));
    } else {
      canvas.drawPath(Path()..moveTo(65, 62)..quadraticBezierTo(73, 66, 74, 96), _line(base, 9));
      canvas.drawCircle(const Offset(74, 100), 4.6, _fill(skin));
    }

    final hem = switch (cut) { 4 => 128.0, 5 => 148.0, _ => 110.0 };
    final cloth = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(base, Colors.white, 0.2)!, base, Color.lerp(base, Colors.black, 0.16)!], stops: const [0, 0.4, 1]).createShader(const Rect.fromLTWH(26, 56, 48, 94));
    if (cut == 5) {
      canvas.drawPath(Path()..moveTo(36, 60)..quadraticBezierTo(50, 56, 64, 60)..lineTo(66, 96)..lineTo(74, hem)..quadraticBezierTo(50, hem + 6, 26, hem)..lineTo(34, 96)..close(), cloth);
      canvas.drawPath(Path()..moveTo(27, hem - 6)..quadraticBezierTo(50, hem, 73, hem - 6), _line(accent, 3));
      canvas.drawPath(Path()..moveTo(36, 62)..lineTo(64, 100)..lineTo(66, 108)..lineTo(34, 70)..close(), _fill(accent));
    } else {
      canvas.drawPath(Path()..moveTo(36, 60)..quadraticBezierTo(50, 56, 64, 60)..lineTo(66, hem - 4)..quadraticBezierTo(66, hem, 62, hem)..lineTo(38, hem)..quadraticBezierTo(34, hem, 34, hem - 4)..close(), cloth);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 50, 8, 12), const Radius.circular(3)), _fill(shade));
    switch (cut) {
      case 1:
        canvas.drawPath(Path()..moveTo(44, 59)..lineTo(50, 66)..lineTo(46, 69)..close(), _fill(accent));
        canvas.drawPath(Path()..moveTo(56, 59)..lineTo(50, 66)..lineTo(54, 69)..close(), _fill(accent));
      case 2:
        canvas.drawPath(Path()..moveTo(42, 60)..quadraticBezierTo(50, 70, 58, 60), _line(accent, 3));
        canvas.drawLine(const Offset(47, 68), const Offset(47, 78), _line(accent, 1.2));
        canvas.drawLine(const Offset(53, 68), const Offset(53, 78), _line(accent, 1.2));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 92, 16, 9), const Radius.circular(3)), _fill(deep.withValues(alpha: 0.35)));
      case 3:
        canvas.drawPath(Path()..moveTo(44, 59)..lineTo(50, 108)..lineTo(56, 59)..quadraticBezierTo(50, 64, 44, 59)..close(), _fill(accent));
        canvas.drawLine(const Offset(44, 59), const Offset(48, 108), _line(deep, 1.3));
        canvas.drawLine(const Offset(56, 59), const Offset(52, 108), _line(deep, 1.3));
      case 4:
        canvas.drawPath(Path()..moveTo(44, 59)..quadraticBezierTo(50, 66, 56, 59), _line(accent, 2.2));
        canvas.drawLine(const Offset(50, 64), const Offset(50, 100), _line(accent, 1.8));
        for (final y in [70.0, 78.0, 86.0, 94.0]) {
          canvas.drawCircle(Offset(50, y), 1.1, _fill(Colors.white.withValues(alpha: 0.7)));
        }
        canvas.drawLine(Offset(34, hem - 5), Offset(66, hem - 5), _line(accent, 2.4));
      case 5:
        break;
      case 6:
        canvas.drawPath(Path()..moveTo(43, 59)..quadraticBezierTo(50, 67, 57, 59), _line(accent, 2.6));
        canvas.drawCircle(const Offset(50, 80), 6, _fill(accent));
        canvas.drawCircle(const Offset(50, 80), 3, _fill(base));
        canvas.drawRect(const Rect.fromLTWH(36, 100, 28, 5), _fill(accent));
      default:
        canvas.drawPath(Path()..moveTo(44, 59)..quadraticBezierTo(50, 66, 56, 59), _line(deep, 2));
        if (c.outfitId == 'outfit_jersey') _text(canvas, '7', const Offset(50, 84), 12, accent);
    }

    onHead(() {
      canvas.drawOval(const Rect.fromLTWH(25.9, 42, 7.2, 10), _fill(shade));
      canvas.drawOval(const Rect.fromLTWH(66.9, 42, 7.2, 10), _fill(shade));
      canvas.drawPath(_face(), Paint()..shader = RadialGradient(center: const Alignment(-0.25, -0.4), radius: 0.95, colors: [Color.lerp(skin, Colors.white, 0.2)!, skin, shade], stops: const [0, 0.62, 1]).createShader(_head));
      _beard(canvas, hair);
      _features(canvas, c.gender == Gender.female);
      _hairFront(canvas, hair);
      _accessory(canvas, _head);
      if (action == null) _moodExtra(canvas);
    });
    canvas.restore();
  }

  Path _face() {
    final (jx, jy, cy) = switch (c.faceShape) {
      FaceShape.round => (66.0, 58.0, 67.0),
      FaceShape.square => (68.0, 62.0, 67.0),
      FaceShape.heart => (57.0, 54.0, 69.0),
      FaceShape.long => (61.0, 58.0, 71.0),
      FaceShape.oval => (62.0, 56.0, 68.0),
    };
    return Path()
      ..moveTo(30, 42)
      ..cubicTo(30, 26, 38, 20, 50, 20)
      ..cubicTo(62, 20, 70, 26, 70, 42)
      ..cubicTo(70, jy, jx, cy, 50, cy)
      ..cubicTo(100 - jx, cy, 30, jy, 30, 42)
      ..close();
  }

  void _moodExtra(Canvas canvas) {
    final bob = sin(idle * 2 * pi) * 1.6;
    switch (c.mood) {
      case Mood.sleepy:
        for (final (i, z) in const [(72.0, 26.0, 7.0), (79.0, 18.0, 9.0), (87.0, 9.0, 11.0)].indexed) {
          _text(canvas, 'z', Offset(z.$1, z.$2 - bob * (i + 1) * 0.5), z.$3, const Color(0xFF5B7BFF));
        }
      case Mood.love:
        _heart(canvas, Offset(80, 20 - bob), 4.6, const Color(0xFFFF4D6D));
        _heart(canvas, Offset(88, 31 + bob * 0.6), 2.8, const Color(0xFFFF8FA3));
      case Mood.excited:
        _sparkle(canvas, Offset(80, 18 - bob), 5.5, const Color(0xFFFFC531));
        _sparkle(canvas, Offset(89, 30), 3, const Color(0xFFFFC531));
        _sparkle(canvas, Offset(18, 22 + bob), 3.6, const Color(0xFFFFC531));
      case Mood.confused:
        _text(canvas, '?', Offset(81, 18 - bob), 16, const Color(0xFF7C4DFF));
      case Mood.sad:
        _drop(canvas, Offset(37.5, 55 + (idle * 6) % 6), 2.2);
      case Mood.worried:
        _drop(canvas, Offset(72, 30 + bob), 2.8);
      case Mood.angry:
        for (final d in const [Offset(1, 1), Offset(-1, 1), Offset(1, -1), Offset(-1, -1)]) {
          canvas.drawLine(Offset(80, 20) + d * 1.6, Offset(80, 20) + d * 5.2, _line(const Color(0xFFE5484D), 2.2));
        }
      default:
        break;
    }
  }

  void _body(Canvas canvas, Color shade) {
    final look = _outfits[c.outfitId] ?? _outfits['outfit_tee']!;
    final base = Color(look.$1), accent = Color(look.$2);
    final deep = Color.lerp(base, Colors.black, 0.3)!;
    final torso = Path()
      ..moveTo(10, 104)
      ..cubicTo(10, 82, 26, 76, 40, 74)
      ..quadraticBezierTo(50, 82, 60, 74)
      ..cubicTo(74, 76, 90, 82, 90, 104)
      ..close();
    canvas.drawPath(torso, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(base, Colors.white, 0.2)!, base, Color.lerp(base, Colors.black, 0.14)!]).createShader(const Rect.fromLTWH(10, 72, 80, 30)));
    canvas.drawPath(Path()..moveTo(43, 62)..lineTo(57, 62)..lineTo(57, 74)..quadraticBezierTo(50, 80, 43, 74)..close(), _fill(shade));
    switch (look.$3) {
      case 1:
        canvas.drawPath(Path()..moveTo(40, 74)..lineTo(50, 85)..lineTo(43, 89)..close(), _fill(accent));
        canvas.drawPath(Path()..moveTo(60, 74)..lineTo(50, 85)..lineTo(57, 89)..close(), _fill(accent));
      case 2:
        canvas.drawPath(Path()..moveTo(38, 75)..quadraticBezierTo(50, 90, 62, 75), _line(accent, 4));
        canvas.drawLine(const Offset(46, 86), const Offset(46, 97), _line(accent, 1.4));
        canvas.drawLine(const Offset(54, 86), const Offset(54, 97), _line(accent, 1.4));
      case 3:
        canvas.drawPath(Path()..moveTo(40, 74)..lineTo(50, 101)..lineTo(60, 74)..quadraticBezierTo(50, 82, 40, 74)..close(), _fill(accent));
        canvas.drawLine(const Offset(40, 74), const Offset(47, 101), _line(deep, 1.6));
        canvas.drawLine(const Offset(60, 74), const Offset(53, 101), _line(deep, 1.6));
      case 4:
        canvas.drawPath(Path()..moveTo(40, 74)..quadraticBezierTo(50, 84, 60, 74), _line(accent, 2.6));
        canvas.drawLine(const Offset(50, 80), const Offset(50, 101), _line(accent, 2.2));
        for (final y in [85.0, 91.0, 97.0]) {
          canvas.drawCircle(Offset(50, y), 1.3, _fill(Color.lerp(accent, Colors.white, 0.45)!));
        }
      case 5:
        canvas.drawPath(Path()..moveTo(22, 102)..quadraticBezierTo(48, 86, 64, 74)..lineTo(72, 78)..quadraticBezierTo(54, 94, 36, 104)..close(), _fill(accent));
        canvas.drawPath(Path()..moveTo(40, 74)..quadraticBezierTo(50, 84, 60, 74), _line(deep, 2));
      case 6:
        canvas.drawPath(Path()..moveTo(39, 74)..quadraticBezierTo(50, 85, 61, 74), _line(accent, 3.2));
        canvas.drawCircle(const Offset(50, 92), 6, _fill(accent));
        canvas.drawCircle(const Offset(50, 92), 3, _fill(base));
      default:
        canvas.drawPath(Path()..moveTo(40, 74)..quadraticBezierTo(50, 84, 60, 74), _line(deep, 2.4));
        if (c.outfitId == 'outfit_jersey') _text(canvas, '7', const Offset(50, 93), 10, accent);
    }
  }

  void _hairBack(Canvas canvas, Color hair) {
    final p = _fill(Color.lerp(hair, Colors.black, 0.22)!);
    switch (c.hairId) {
      case 'hair_long' || 'hair_braids':
        canvas.drawPath(Path()..moveTo(26, 44)..cubicTo(24, 22, 38, 13, 50, 13)..cubicTo(62, 13, 76, 22, 74, 44)..lineTo(76, 80)..quadraticBezierTo(64, 86, 62, 70)..lineTo(38, 70)..quadraticBezierTo(36, 86, 24, 80)..close(), p);
      case 'hair_wavy':
        canvas.drawPath(Path()..moveTo(26, 44)..cubicTo(24, 22, 38, 13, 50, 13)..cubicTo(62, 13, 76, 22, 74, 44)..quadraticBezierTo(82, 56, 74, 66)..quadraticBezierTo(80, 76, 68, 76)..lineTo(32, 76)..quadraticBezierTo(20, 76, 26, 66)..quadraticBezierTo(18, 56, 26, 44)..close(), p);
      case 'hair_bob':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(24, 14, 76, 66), const Radius.circular(22)), p);
      case 'hair_afro':
        canvas.drawCircle(const Offset(50, 31), 31, p);
      case 'hair_ponytail':
        canvas.drawPath(Path()..moveTo(68, 26)..quadraticBezierTo(90, 30, 82, 66)..quadraticBezierTo(74, 58, 72, 44)..close(), p);
      case 'hair_bun' || 'hair_top_knot':
        canvas.drawCircle(const Offset(50, 11), 9, p);
      case 'hair_pigtails':
        canvas.drawCircle(const Offset(22, 54), 8.5, p);
        canvas.drawCircle(const Offset(78, 54), 8.5, p);
      case 'hair_long_curls':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(21, 14, 79, 84), const Radius.circular(22)), p);
      case 'hair_man_bun':
        canvas.drawCircle(const Offset(52, 12), 6.5, p);
      default:
        break;
    }
  }

  void _hairFront(Canvas canvas, Color hair) {
    final p = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(hair, Colors.white, 0.16)!, hair]).createShader(const Rect.fromLTWH(24, 8, 52, 38));
    final shine = _line(Colors.white.withValues(alpha: 0.2), 2);
    final crop = Path()..moveTo(29, 44)..cubicTo(27, 24, 38, 15, 51, 15)..cubicTo(64, 15, 73, 24, 71, 44)..cubicTo(69, 36, 66, 31, 61, 29)..cubicTo(54, 33, 42, 33, 35, 30)..cubicTo(32, 33, 30, 38, 29, 44)..close();
    final swept = Path()..moveTo(29, 44)..cubicTo(27, 24, 38, 15, 50, 15)..cubicTo(62, 15, 73, 24, 71, 44)..cubicTo(68, 34, 62, 28, 52, 26)..cubicTo(46, 32, 36, 34, 29, 44)..close();
    final buzz = Path()..moveTo(29, 42)..cubicTo(28, 24, 38, 16, 50, 16)..cubicTo(62, 16, 72, 24, 71, 42)..cubicTo(69, 34, 64, 27, 50, 27)..cubicTo(36, 27, 31, 34, 29, 42)..close();
    final puff = Path()..moveTo(36, 26)..cubicTo(34, 8, 62, 6, 66, 24)..cubicTo(58, 20, 46, 20, 36, 26)..close();
    switch (c.hairId) {
      case 'hair_buzz':
        canvas.drawPath(buzz, _fill(hair.withValues(alpha: 0.82)));
      case 'hair_undercut':
        canvas.drawPath(buzz, _fill(hair.withValues(alpha: 0.82)));
        canvas.drawPath(puff, p);
      case 'hair_long' || 'hair_wavy' || 'hair_bob' || 'hair_ponytail' || 'hair_bun' || 'hair_braids' || 'hair_pigtails':
        canvas.drawPath(swept, p);
        if (c.hairId == 'hair_braids') {
          for (final x in [25.5, 74.5]) {
            for (var i = 0; i < 5; i++) {
              canvas.drawCircle(Offset(x, 52 + i * 7.0), 4.3, p);
            }
          }
        }
      case 'hair_side_part':
        canvas.drawPath(Path()..moveTo(29, 44)..cubicTo(27, 24, 38, 15, 51, 15)..cubicTo(64, 15, 73, 24, 71, 44)..cubicTo(70, 36, 66, 30, 60, 27)..cubicTo(50, 35, 38, 35, 31, 38)..close(), p);
      case 'hair_pixie':
        canvas.drawPath(Path()..moveTo(29, 44)..cubicTo(27, 24, 38, 15, 50, 15)..cubicTo(62, 15, 73, 24, 71, 44)..cubicTo(70, 38, 68, 34, 64, 31)..cubicTo(56, 40, 40, 38, 33, 30)..cubicTo(31, 34, 30, 38, 29, 44)..close(), p);
      case 'hair_quiff':
        canvas.drawPath(crop, p);
        canvas.drawPath(puff, p);
      case 'hair_spiky':
        canvas.drawPath(crop, p);
        for (var i = 0; i < 5; i++) {
          final x = 34 + i * 8.0;
          canvas.drawPath(Path()..moveTo(x - 5, 22)..lineTo(x + (i - 2) * 1.5, 7)..lineTo(x + 5, 22)..close(), p);
        }
      case 'hair_curly' || 'hair_afro' || 'hair_long_curls':
        for (var i = 0; i < 9; i++) {
          final a = pi + i * pi / 8;
          canvas.drawCircle(Offset(50 + cos(a) * 20.5, 33 + sin(a) * 17), 7.6, p);
        }
        canvas.drawPath(crop, p);
      case 'hair_mohawk':
        canvas.drawPath(Path()..moveTo(44, 30)..cubicTo(42, 8, 58, 8, 56, 30)..quadraticBezierTo(50, 26, 44, 30)..close(), p);
      default:
        canvas.drawPath(crop, p);
    }
    canvas.drawPath(Path()..moveTo(39, 22)..quadraticBezierTo(48, 17, 58, 20), shine);
  }

  void _beard(Canvas canvas, Color hair) {
    if (c.gender == Gender.female || c.beard == Beard.none) return;
    final p = _fill(hair.withValues(alpha: 0.92));
    final jaw = Path()
      ..moveTo(31.5, 50)
      ..cubicTo(32, 62, 40, 69, 50, 69)
      ..cubicTo(60, 69, 68, 62, 68.5, 50)
      ..cubicTo(64, 60, 58, 62.5, 50, 62.5)
      ..cubicTo(42, 62.5, 36, 60, 31.5, 50)
      ..close();
    final mustache = Path()..moveTo(42.5, 57.2)..quadraticBezierTo(50, 53.6, 57.5, 57.2)..quadraticBezierTo(50, 56.2, 42.5, 57.2)..close();
    switch (c.beard) {
      case Beard.stubble:
        canvas.drawPath(jaw, _fill(hair.withValues(alpha: 0.26)));
      case Beard.mustache:
        canvas.drawPath(mustache, _line(hair, 2.2));
      case Beard.goatee:
        canvas.drawPath(mustache, _line(hair, 2));
        canvas.drawOval(const Rect.fromLTWH(45.5, 62.5, 9, 6.5), p);
      case Beard.chinStrap:
        canvas.drawPath(Path()..moveTo(32, 50)..cubicTo(33, 62, 41, 68, 50, 68)..cubicTo(59, 68, 67, 62, 68, 50), _line(hair, 2.6));
      case Beard.full:
        canvas.drawPath(jaw, p);
        canvas.drawPath(mustache, _line(hair, 2.2));
      case Beard.none:
        break;
    }
  }

  void _features(Canvas canvas, bool female) {
    final mood = c.mood ?? Mood.happy;
    final blinking = idle > 0.94 && idle < 0.985;
    final laughing = action == AvatarAction.laugh;
    final blush = _fill(const Color(0xFFFF6B8A).withValues(alpha: female ? 0.32 : 0.22));
    canvas.drawOval(const Rect.fromLTWH(31.9, 50, 9.2, 6), blush);
    canvas.drawOval(const Rect.fromLTWH(58.9, 50, 9.2, 6), blush);

    final lift = switch (mood) { Mood.angry => 2.2, Mood.sad || Mood.worried => -2.0, _ => 0.0 };
    final raise = mood == Mood.smart || mood == Mood.confused ? 2.4 : 0.0;
    final brow = _line(_ink, female ? 1.5 : 2);
    canvas.drawPath(Path()..moveTo(36, 38.5 - lift)..quadraticBezierTo(40.5, 36 - lift.abs() * 0.2, 45, 38.5 + lift), brow);
    canvas.drawPath(Path()..moveTo(55, 38.5 + lift - raise)..quadraticBezierTo(59.5, 36 - raise - lift.abs() * 0.2, 64, 38.5 - lift - raise), brow);

    for (final x in [40.5, 59.5]) {
      final winking = action == AvatarAction.wink && x > 50 && t > 0.2 && t < 0.8;
      if (mood == Mood.love && !blinking) {
        _heart(canvas, Offset(x, 45.6), 3.4, const Color(0xFFFF4D6D));
      } else if (blinking || winking || laughing || mood == Mood.sleepy) {
        canvas.drawArc(Rect.fromCenter(center: Offset(x, 45.5), width: 7, height: 5), laughing ? pi : 0, pi, false, _line(_ink, 1.9));
      } else {
        final wide = mood == Mood.excited || mood == Mood.worried ? 1.15 : 1.0;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, 45.5), width: 6 * wide, height: 7.6 * wide), _fill(_ink));
        canvas.drawCircle(Offset(x + 1.1, 44), 1.25, _fill(Colors.white));
        canvas.drawCircle(Offset(x - 0.9, 47), 0.6, _fill(Colors.white.withValues(alpha: 0.8)));
        if (female) canvas.drawLine(Offset(x + (x < 50 ? -3 : 3), 42.6), Offset(x + (x < 50 ? -4.8 : 4.8), 41), _line(_ink, 1));
      }
    }
    canvas.drawPath(Path()..moveTo(48.4, 52.5)..quadraticBezierTo(50, 54.2, 51.6, 52.5), _line(Colors.black.withValues(alpha: 0.22), 1.2));

    const lip = Color(0xFF8C2F39);
    final mouth = _line(lip, 2.2);
    if (laughing || mood == Mood.excited || mood == Mood.love) {
      canvas.drawPath(Path()..moveTo(43.5, 57.5)..quadraticBezierTo(50, 67, 56.5, 57.5)..close(), _fill(lip));
      canvas.drawPath(Path()..moveTo(46.2, 61.4)..quadraticBezierTo(50, 64.6, 53.8, 61.4)..quadraticBezierTo(50, 59.8, 46.2, 61.4)..close(), _fill(const Color(0xFFFF8FA3)));
    } else if (mood == Mood.sad || mood == Mood.angry) {
      canvas.drawPath(Path()..moveTo(44.5, 61.5)..quadraticBezierTo(50, 56.5, 55.5, 61.5), mouth);
    } else if (mood == Mood.worried || mood == Mood.confused) {
      canvas.drawPath(Path()..moveTo(44, 60)..quadraticBezierTo(47, 57.5, 50, 60)..quadraticBezierTo(53, 62.5, 56, 60), mouth);
    } else if (mood == Mood.sleepy || mood == Mood.neutral) {
      canvas.drawLine(const Offset(45.5, 60), const Offset(54.5, 60), mouth);
    } else if (mood == Mood.smart) {
      canvas.drawPath(Path()..moveTo(44.5, 59.5)..quadraticBezierTo(51, 62.5, 56.5, 57.5), mouth);
    } else {
      canvas.drawPath(Path()..moveTo(44, 58)..quadraticBezierTo(50, 64, 56, 58), mouth);
    }
  }

  void _accessory(Canvas canvas, Rect head) {
    const gold = Color(0xFFF5B301);
    switch (c.accessoryId) {
      case 'acc_bindi':
        canvas.drawCircle(const Offset(50, 33.5), 1.7, _fill(const Color(0xFFD60036)));
      case 'acc_tilak':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(50, 32.5), width: 2.2, height: 6.5), const Radius.circular(1.1)), _fill(const Color(0xFFD60036)));
      case 'acc_round_glasses':
        for (final x in [40.0, 60.0]) {
          canvas.drawCircle(Offset(x, 45.5), 6.2, _line(gold, 1.4));
        }
        canvas.drawLine(const Offset(46.2, 45), const Offset(53.8, 45), _line(gold, 1.4));
      case 'acc_bandana':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.left - 1, head.top + 9, head.width + 2, 6), const Radius.circular(3)), _fill(const Color(0xFFDC2626)));
        canvas.drawPath(Path()..moveTo(head.right, head.top + 12)..lineTo(head.right + 8, head.top + 8)..lineTo(head.right + 7, head.top + 18)..close(), _fill(const Color(0xFFB91C1C)));
      case 'acc_scarf':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(37, 70, 63, 78), const Radius.circular(4)), _fill(const Color(0xFF0EA5E9)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(54, 76, 61, 92), const Radius.circular(3)), _fill(const Color(0xFF0284C7)));
      case 'acc_flower_crown':
        for (var i = 0; i < 5; i++) {
          final a = pi * (1.15 + i * 0.175);
          canvas.drawCircle(Offset(50 + cos(a) * 21, head.top + 20 + sin(a) * 19), 3.6, _fill(i.isEven ? const Color(0xFFF472B6) : const Color(0xFFFDE047)));
        }
      case 'acc_tiara':
        canvas.drawArc(Rect.fromLTRB(head.left + 5, head.top - 1, head.right - 5, head.top + 22), pi * 1.15, pi * 0.7, false, _line(gold, 2));
        canvas.drawCircle(Offset(50, head.top - 2), 2.4, _fill(const Color(0xFF38BDF8)));
      case 'acc_earrings':
        canvas.drawCircle(Offset(head.left - 0.5, 53.5), 2.2, _fill(gold));
        canvas.drawCircle(Offset(head.right + 0.5, 53.5), 2.2, _fill(gold));
      case 'acc_nose_ring':
        canvas.drawCircle(const Offset(47.4, 53.2), 1.6, _line(gold, 0.9));
      case 'acc_glasses' || 'acc_sunglasses':
        final dark = c.accessoryId == 'acc_sunglasses';
        for (final x in [40.0, 60.0]) {
          final lens = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 45.5), width: 13, height: 10.5), const Radius.circular(4.5));
          if (dark) canvas.drawRRect(lens, _fill(const Color(0xEE101014)));
          canvas.drawRRect(lens, _line(const Color(0xFF1F2937), 1.5));
        }
        canvas.drawLine(const Offset(46.5, 45), const Offset(53.5, 45), _line(const Color(0xFF1F2937), 1.5));
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
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 47), width: 8, height: 15), const Radius.circular(4)), _fill(const Color(0xFFEF4444)));
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
