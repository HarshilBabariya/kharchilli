import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/notifier.dart';
import 'avatar.dart';
import 'glyphs.dart';
import 'theme.dart';
import 'widgets.dart';

enum Burst { confetti, fireworks, colours, snow, petals, kites, lights }

Burst burstFor(FestivalPack pack) => switch (pack) {
      FestivalPack.diwali || FestivalPack.newYear => Burst.fireworks,
      FestivalPack.holi => Burst.colours,
      FestivalPack.christmas => Burst.snow,
      FestivalPack.uttarayan => Burst.kites,
      FestivalPack.tiranga => Burst.confetti,
      FestivalPack.ganesh || FestivalPack.rakhi => Burst.petals,
      FestivalPack.navratri => Burst.lights,
    };

List<Color> coloursFor(FestivalPack pack) {
  if (pack == FestivalPack.tiranga) return const [Color(0xFFFF9933), Colors.white, Color(0xFF138808)];
  if (pack == FestivalPack.christmas) return const [Colors.white, Color(0xFFE3F2FD)];
  final p = paletteOf(pack.themeId);
  return [Color(p.primary), Color(p.secondary), Color(p.tertiary)];
}

const partyColours = [Color(0xFFE8203F), Color(0xFFFFB627), Color(0xFF2EC4B6), Color(0xFF7C4DFF), Color(0xFFFF6FB5), Color(0xFF3B82F6)];

/// A particle show driven purely by time, so it needs no per-frame state.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, required this.kind, this.colours = partyColours, this.loop = false, this.duration = const Duration(milliseconds: 3200), this.onDone});
  final Burst kind;
  final List<Color> colours;
  final bool loop;
  final Duration duration;
  final VoidCallback? onDone;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.loop) {
      _c.repeat();
    } else {
      _c.forward().whenComplete(() => widget.onDone?.call());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(size: Size.infinite, painter: _ParticlePainter(widget.kind, widget.colours, _c.value, widget.loop))),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.kind, this.colours, this.t, this.loop);
  final Burst kind;
  final List<Color> colours;
  final double t;
  final bool loop;

  static double _r(int seed, int salt) {
    final x = sin(seed * 127.1 + salt * 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case Burst.confetti:
        _falling(canvas, size, 90, confetti: true);
      case Burst.snow:
        _falling(canvas, size, 70, round: true);
      case Burst.petals || Burst.lights:
        _falling(canvas, size, 60, glow: kind == Burst.lights);
      case Burst.fireworks:
        _fireworks(canvas, size);
      case Burst.colours:
        _colours(canvas, size);
      case Burst.kites:
        _kites(canvas, size);
    }
  }

  void _falling(Canvas canvas, Size size, int count, {bool confetti = false, bool round = false, bool glow = false}) {
    final fade = loop ? 1.0 : (1 - (t - 0.75).clamp(0.0, 0.25) * 4).toDouble();
    for (var i = 0; i < count; i++) {
      final delay = _r(i, 1) * (loop ? 1 : 0.35);
      final speed = 0.8 + _r(i, 2) * 0.9;
      var life = (t - delay) * speed * (loop ? 1 : 1.5);
      if (loop) life = (life % 1 + 1) % 1;
      if (life < 0) continue;
      final x = _r(i, 3) * size.width + sin(life * 6 + i) * 22;
      final y = -30 + life * (size.height + 60);
      final colour = colours[i % colours.length].withValues(alpha: fade * (round ? 0.9 : 1));
      final s = 5 + _r(i, 4) * 7;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(life * 9 * (_r(i, 5) - 0.5) * 2);
      if (confetti) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 1.5, height: s * 0.8 * cos(life * 14 + i).abs() + 1.5), const Radius.circular(1.5)), Paint()..color = colour);
      } else if (round) {
        canvas.drawCircle(Offset.zero, s * 0.38, Paint()..color = colour);
      } else {
        if (glow) canvas.drawCircle(Offset.zero, s, Paint()..color = colour.withValues(alpha: 0.22 * fade));
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: glow ? s * 0.8 : s * 1.3, height: s * 0.8), Paint()..color = colour);
      }
      canvas.restore();
    }
  }

  void _fireworks(Canvas canvas, Size size) {
    for (var b = 0; b < 4; b++) {
      final start = b * 0.2;
      final local = ((t - start) / 0.42).clamp(0.0, 1.0).toDouble();
      if (local <= 0 || local >= 1) continue;
      final centre = Offset(size.width * (0.2 + _r(b, 7) * 0.6), size.height * (0.18 + _r(b, 8) * 0.3));
      if (local < 0.3) {
        final rise = local / 0.3;
        final from = Offset(centre.dx, size.height);
        final head = Offset.lerp(from, centre, Curves.easeOut.transform(rise))!;
        canvas.drawLine(Offset.lerp(from, centre, max(rise - 0.25, 0.0))!, head, Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFD27A));
        continue;
      }
      final burst = Curves.easeOutCubic.transform((local - 0.3) / 0.7);
      final fade = 1 - (local - 0.3) / 0.7;
      for (var i = 0; i < 46; i++) {
        final angle = i / 46 * 2 * pi + _r(i, b) * 0.3;
        final reach = size.width * (0.16 + _r(i, b + 11) * 0.2) * burst;
        final p = centre + Offset(cos(angle) * reach, sin(angle) * reach + burst * burst * 46);
        final colour = colours[(i + b) % colours.length].withValues(alpha: fade);
        canvas.drawCircle(p, 2.4 + 2.2 * fade, Paint()..color = colour);
        canvas.drawLine(p, Offset.lerp(p, centre, 0.12)!, Paint()
          ..strokeWidth = 1.6
          ..color = colour.withValues(alpha: fade * 0.5));
      }
    }
  }

  void _colours(Canvas canvas, Size size) {
    for (var i = 0; i < 12; i++) {
      final start = _r(i, 1) * 0.5;
      final local = ((t - start) / 0.5).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;
      final centre = Offset(_r(i, 2) * size.width, size.height * (0.15 + _r(i, 3) * 0.7));
      final grow = Curves.easeOutCubic.transform(local);
      final colour = colours[i % colours.length];
      canvas.drawCircle(centre, size.width * (0.08 + _r(i, 4) * 0.14) * grow, Paint()..color = colour.withValues(alpha: 0.42 * (1 - local)));
      for (var d = 0; d < 9; d++) {
        final angle = d / 9 * 2 * pi + i;
        final reach = size.width * 0.22 * grow * (0.5 + _r(d, i) * 0.5);
        canvas.drawCircle(centre + Offset(cos(angle) * reach, sin(angle) * reach + grow * 30), 4 * (1 - local) + 1.5, Paint()..color = colour.withValues(alpha: 1 - local));
      }
    }
  }

  void _kites(Canvas canvas, Size size) {
    for (var i = 0; i < 4; i++) {
      final local = ((t - i * 0.1) / 0.75).clamp(0.0, 1.0).toDouble();
      if (local <= 0 || local >= 1) continue;
      final x = size.width * (0.1 + 0.8 * _r(i, 2)) + sin(local * 6 + i) * 30;
      final y = size.height * (1.05 - local * 1.2);
      const s = 26.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(sin(local * 9 + i) * 0.25);
      final a = colours[i % colours.length], b = colours[(i + 1) % colours.length];
      canvas.drawPath(Path()..moveTo(0, -s)..lineTo(s * 0.8, 0)..lineTo(0, s)..close(), Paint()..color = a);
      canvas.drawPath(Path()..moveTo(0, -s)..lineTo(-s * 0.8, 0)..lineTo(0, s)..close(), Paint()..color = b);
      final tail = Path()..moveTo(0, s);
      for (var k = 1; k <= 5; k++) {
        tail.lineTo(sin(local * 12 + k) * 8, s + k * 12);
      }
      canvas.drawPath(tail, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = a);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class Flame extends StatefulWidget {
  const Flame({super.key, this.size = 44, this.lit = true});
  final double size;
  final bool lit;

  @override
  State<Flame> createState() => _FlameState();
}

class _FlameState extends State<Flame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(size: Size.square(widget.size), painter: _FlamePainter(_c.value, widget.lit, context.cs.onSurfaceVariant)));
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.t, this.lit, this.off);
  final double t;
  final bool lit;
  final Color off;

  Path _flame(Size s, double scale, double sway) {
    final w = s.width, h = s.height;
    final cx = w / 2 + sway;
    return Path()
      ..moveTo(cx, h * (1 - scale))
      ..cubicTo(w * (0.5 + 0.42 * scale), h * (1 - 0.55 * scale), w * (0.5 + 0.4 * scale), h * 0.98, w / 2, h * 0.98)
      ..cubicTo(w * (0.5 - 0.4 * scale), h * 0.98, w * (0.5 - 0.42 * scale), h * (1 - 0.55 * scale), cx, h * (1 - scale))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!lit) {
      canvas.drawPath(_flame(size, 0.9, 0), Paint()..color = off.withValues(alpha: 0.35));
      return;
    }
    final flick = sin(t * 2 * pi), flick2 = sin(t * 4 * pi + 1);
    final rect = Offset.zero & size;
    canvas.drawPath(_flame(size, 0.94 + flick * 0.05, flick2 * 1.6), Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFF3D2E), Color(0xFFFF8A1F)]).createShader(rect));
    canvas.drawPath(_flame(size, 0.66 + flick2 * 0.05, -flick * 1.2), Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFFB627), Color(0xFFFFE58A)]).createShader(rect));
    canvas.drawPath(_flame(size, 0.36 + flick * 0.03, 0), Paint()..color = const Color(0xFFFFF7D6));
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}

/// Shows queued level, badge, streak and festival celebrations one at a time, plus the points toast and festive moments.
class CelebrationHost extends StatefulWidget {
  const CelebrationHost({super.key, required this.child});
  final Widget child;

  @override
  State<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends State<CelebrationHost> {
  bool _showing = false;
  int _toastKey = 0;
  int _momentKey = 0;
  bool _moment = false;
  AppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!identical(app, _app)) {
      _app?.pointsToast.removeListener(_onToast);
      _app?.festiveMoment.removeListener(_onMoment);
      _app = app
        ..pointsToast.addListener(_onToast)
        ..festiveMoment.addListener(_onMoment);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  @override
  void dispose() {
    _app?.pointsToast.removeListener(_onToast);
    _app?.festiveMoment.removeListener(_onMoment);
    super.dispose();
  }

  void _onToast() {
    if (mounted && _app!.pointsToast.value > 0) setState(() => _toastKey++);
  }

  void _onMoment() {
    if (mounted) {
      setState(() {
        _moment = true;
        _momentKey++;
      });
    }
  }

  Future<void> _next() async {
    final app = _app;
    if (!mounted || _showing || app == null || app.locked || app.celebrations.isEmpty) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      Future.delayed(const Duration(milliseconds: 350), _next);
      return;
    }
    _showing = true;
    final c = app.celebrations.removeAt(0);
    HapticFeedback.heavyImpact();
    Sfx.play(c.sound);
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => _CelebrationScreen(c),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
    if (c.kind == CelebrationKind.festival) await app.markFestivalSeen();
    _showing = false;
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app!;
    final f = app.festival;
    return Stack(children: [
      widget.child,
      if (_moment && f != null)
        Positioned.fill(
          child: ParticleField(key: ValueKey('moment$_momentKey'), kind: burstFor(f.festival.pack), colours: coloursFor(f.festival.pack), onDone: () {
            if (mounted) setState(() => _moment = false);
          }),
        ),
      if (_toastKey > 0)
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('toast$_toastKey'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1900),
                builder: (_, v, child) => Opacity(
                  opacity: v < 0.15 ? v / 0.15 : (v > 0.75 ? (1 - v) / 0.25 : 1),
                  child: Transform.translate(offset: Offset(0, 24 - 46 * Curves.easeOutCubic.transform(v)), child: Transform.scale(scale: 0.8 + 0.2 * Curves.elasticOut.transform(min(v * 2.5, 1.0)), child: child)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF1D1517), borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 8))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Coin(size: 22), const SizedBox(width: 8), Text(tr('toast_points', [app.pointsToast.value]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _CelebrationScreen extends StatefulWidget {
  const _CelebrationScreen(this.c);
  final Celebration c;

  @override
  State<_CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<_CelebrationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = widget.c;
    final cs = context.cs;
    final pack = c.festival?.festival.pack;
    final glow = switch (c.kind) {
      CelebrationKind.badge => const Color(0xFFFFB627),
      CelebrationKind.streak => const Color(0xFFFF8A1F),
      CelebrationKind.level => const Color(0xFFFFB627),
      CelebrationKind.festival => cs.primary,
    };
    final Widget art = switch (c.kind) {
      CelebrationKind.badge => Medal(c.badgeId ?? 'badge_first_step', size: 140),
      CelebrationKind.streak => const Flame(size: 128),
      CelebrationKind.level => const Medal('badge_level_5', size: 140),
      CelebrationKind.festival => AvatarView(pack == null ? app.myLook : RewardCatalog.dressFor(pack, app.myLook), size: 84, animate: true, action: AvatarAction.cheer, full: true),
    };
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(child: ParticleField(kind: pack == null ? Burst.confetti : burstFor(pack), colours: pack == null ? partyColours : coloursFor(pack), loop: true, duration: const Duration(milliseconds: 4200))),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 620),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: child)),
              child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: [
                Container(
                  margin: const EdgeInsets.only(top: 84),
                  padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: glow.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 60, spreadRadius: 2)],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(c.title, textAlign: TextAlign.center, style: context.tt.headlineSmall),
                    const SizedBox(height: 10),
                    Text(c.body, textAlign: TextAlign.center, style: context.tt.bodyLarge!.copyWith(color: cs.onSurfaceVariant)),
                    if (pack != null) ...[
                      const SizedBox(height: 10),
                      Text(tr('fest_gift_hint', [RewardCatalog.find(pack.themeId)?.name ?? '', PointsRules.festivalGift]), textAlign: TextAlign.center, style: context.tt.bodySmall),
                    ],
                    const SizedBox(height: 22),
                    if (pack != null && !app.festivalClaimed) ...[
                      KButton(tr('fest_claim', [PointsRules.festivalGift]), onTap: () async {
                        final nav = Navigator.of(context);
                        await app.claimFestival();
                        nav.pop();
                      }),
                      const SizedBox(height: 8),
                      KButton(tr('later'), tonal: true, onTap: () => Navigator.of(context).pop()),
                    ] else
                      KButton(tr('celebrate_keep_going'), onTap: () => Navigator.of(context).pop()),
                  ]),
                ),
                SizedBox(
                  width: 190,
                  height: 170,
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedBuilder(animation: _spin, builder: (_, __) => CustomPaint(size: const Size.square(190), painter: _RaysPainter(_spin.value, glow))),
                    art,
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The slowly turning sunburst behind a celebration's artwork.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.turn, this.color);
  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    final ray = Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = turn * 2 * pi + i * pi / 6;
      canvas.drawPath(Path()..moveTo(c.dx, c.dy)..lineTo(c.dx + cos(a - 0.09) * r, c.dy + sin(a - 0.09) * r)..lineTo(c.dx + cos(a + 0.09) * r, c.dy + sin(a + 0.09) * r)..close(), ray);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.turn != turn;
}
