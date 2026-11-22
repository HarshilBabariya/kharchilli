import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ad_service.dart';
import '../core/app_state.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import 'theme.dart';
import 'widgets.dart';

class SpinWheelSection extends StatefulWidget {
  const SpinWheelSection({super.key});

  @override
  State<SpinWheelSection> createState() => _SpinWheelSectionState();
}

class _SpinWheelSectionState extends State<SpinWheelSection> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  Animation<double>? _anim;
  double _angle = 0;
  bool _spinning = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static IconData _iconFor(String id) => switch (id) {
        'themes' => Icons.palette_rounded,
        'sfx' => Icons.music_note_rounded,
        'avatar' => Icons.face_retouching_natural_rounded,
        'insights' => Icons.insights_rounded,
        'ad_free' => Icons.block_rounded,
        'all_access' => Icons.auto_awesome_rounded,
        _ => Icons.star_rounded,
      };

  Future<void> _spin({required bool usedAd}) async {
    if (_spinning) return;
    final app = AppScope.read(context);
    final rng = Random();
    final winner = SpinWheelCatalog.pickWeighted(rng.nextInt(100));
    final idx = SpinWheelCatalog.slices.indexOf(winner);
    final sliceAngle = (2 * pi) / SpinWheelCatalog.slices.length;

    final targetSliceCenter = (idx + 0.5) * sliceAngle;
    final fullTurns = 5 * 2 * pi;
    final currentMod = _angle % (2 * pi);
    final desiredMod = (2 * pi - targetSliceCenter) % (2 * pi);
    final delta = fullTurns + ((desiredMod - currentMod) % (2 * pi));

    setState(() => _spinning = true);
    _anim = Tween<double>(begin: _angle, end: _angle + delta).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.reset();
    await _ctrl.forward();
    _angle = _anim!.value % (2 * pi);

    final res = await app.applySpinWin(winner, usedAd: usedAd);
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() => _spinning = false);

    final msg = res.convertedToAdFree
        ? tr('spin_won_ad_free_fallback')
        : winner.ownable
            ? tr('spin_won_ownable', [tr(winner.labelKey), res.newPercent])
            : tr('spin_won_boost', [tr(winner.labelKey)]);
    toast(context, msg);
  }

  void _onSpinTap(AppState app) {
    if (_spinning) return;
    if (app.canFreeSpinToday) {
      _spin(usedAd: false);
      return;
    }
    if (app.remainingAdSpinsToday <= 0) {
      toast(context, tr('spin_limit_reached'));
      return;
    }
    AdService.instance.showRewardedAd(
      onRewardEarned: () => _spin(usedAd: true),
      onUnavailable: () => toast(context, tr('ad_not_ready')),
    );
  }

  void _showOdds(BuildContext context) {
    showKSheet<void>(
      context,
      title: tr('spin_odds_title'),
      builder: (sheet) => Column(children: [
        for (final s in SpinWheelCatalog.slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              IconTile(_iconFor(s.id), color: Color(s.colorValue), size: 36),
              const SizedBox(width: 12),
              Expanded(child: Text(tr(s.labelKey), style: sheet.tt.titleSmall)),
              Pill('${s.weight}%', color: Color(s.colorValue)),
            ]),
          ),
      ]),
    );
  }

  String _fmtRemaining(Duration d) => d.inHours > 0 ? '${d.inHours}h ${d.inMinutes.remainder(60)}m' : '${d.inMinutes}m';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final free = app.canFreeSpinToday;
    final adLeft = app.remainingAdSpinsToday;
    final canSpin = !_spinning && (free || adLeft > 0);
    final labels = [for (final s in SpinWheelCatalog.slices) tr(s.labelKey)];

    return Column(children: [
      const SizedBox(height: 10),
      KCard(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(children: [
          Row(children: [
            IconTile(Icons.auto_awesome_rounded, color: cs.primary, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('spin_title'), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(tr('spin_subtitle'), style: context.tt.bodySmall),
              ]),
            ),
            const SizedBox(width: 8),
            RoundIcon(Icons.info_outline_rounded, onTap: () => _showOdds(context)),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            width: 278,
            height: 288,
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              Positioned(
                top: 16,
                child: Container(
                  width: 264,
                  height: 264,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                    border: Border.all(color: cs.outlineVariant, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: context.isDark ? 0.28 : 0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _anim?.value ?? _angle,
                      child: CustomPaint(
                        painter: _WheelPainter(
                          slices: SpinWheelCatalog.slices,
                          labels: labels,
                          rimColor: cs.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Center tappable hub matching Gharcha's hero gradient
              Positioned(
                top: 118,
                child: Pressable(
                  scale: 0.9,
                  onTap: canSpin ? () => _onSpinTap(app) : null,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: context.heroGradient,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _spinning ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              // Floating pointer cleanly overlapping the top rim
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: const Size(34, 34),
                  painter: _PointerPainter(color: cs.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          KButton(
            free
                ? tr('spin_free_btn')
                : adLeft > 0
                    ? tr('spin_ad_btn', [adLeft])
                    : tr('spin_limit_reached'),
            icon: free ? Icons.auto_awesome_rounded : Icons.play_circle_filled_rounded,
            onTap: canSpin ? () => _onSpinTap(app) : null,
          ),
        ]),
      ),
      const SizedBox(height: 14),
      KCard(
        radius: 26,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('spin_progress_title'), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final s in SpinWheelCatalog.slices.where((s) => s.ownable))
            Builder(builder: (_) {
              final pct = app.ownProgressOf(s.id);
              final rem = app.remainingUnlock(s.id);
              final tint = Color(s.colorValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  IconTile(_iconFor(s.id), color: tint, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(tr(s.labelKey), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall)),
                        const SizedBox(width: 6),
                        if (pct >= 100)
                          Pill(tr('owned'), color: good)
                        else if (rem != null)
                          Pill('${_fmtRemaining(rem)} · $pct%', color: tint)
                        else
                          Text('$pct%', style: context.tt.labelMedium!.copyWith(color: cs.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 7),
                      KProgress(pct / 100, color: pct >= 100 ? good : tint, height: 8),
                    ]),
                  ),
                ]),
              );
            }),
        ]),
      ),
    ]);
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.slices, required this.labels, required this.rimColor});
  final List<SpinSlice> slices;
  final List<String> labels;
  final Color rimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = (2 * pi) / slices.length;

    for (var i = 0; i < slices.length; i++) {
      final start = -pi / 2 + i * sweep;
      final base = Color(slices[i].colorValue);
      final lighter = Color.lerp(base, Colors.white, 0.18)!;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [lighter, base],
          radius: 0.95,
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, paint);

      // Subtle white divider between slices
      final border = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, border);

      // Draw crisp label radially along the middle of each slice
      final mid = start + sweep / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(mid);

      final shortLabel = labels[i].replaceAll(' (8h)', '').replaceAll(' (8 घंटे)', '').replaceAll(' (8 કલાક)', '');
      final tp = TextPainter(
        text: TextSpan(
          text: shortLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            shadows: [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.58);

      tp.paint(canvas, Offset(radius * 0.34, -tp.height / 2));
      canvas.restore();
    }

    // Outer white ring + 12 decorative rim pegs
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final pegPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < 12; i++) {
      final a = i * (2 * pi / 12);
      final p = Offset(center.dx + cos(a) * (radius - 6), center.dy + sin(a) * (radius - 6));
      canvas.drawCircle(p, 2.5, pegPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.labels != labels || old.rimColor != rimColor;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width * 0.14, size.height * 0.28)
      ..quadraticBezierTo(size.width / 2, 0, size.width * 0.86, size.height * 0.28)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 5, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}
