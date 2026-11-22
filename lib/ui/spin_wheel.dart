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
              Container(width: 14, height: 14, decoration: BoxDecoration(color: Color(s.colorValue), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(tr(s.labelKey), style: sheet.tt.titleSmall)),
              Pill('${s.weight}%', color: Color(s.colorValue)),
            ]),
          ),
      ]),
    );
  }

  String _fmtRemaining(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final free = app.canFreeSpinToday;
    final adLeft = app.remainingAdSpinsToday;

    return Column(children: [
      const SizedBox(height: 10),
      KCard(
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(tr('spin_title'), style: context.tt.titleLarge)),
            RoundIcon(Icons.info_outline_rounded, onTap: () => _showOdds(context)),
          ]),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerLeft, child: Text(tr('spin_subtitle'), style: context.tt.bodySmall)),
          const SizedBox(height: 18),
          Stack(alignment: Alignment.topCenter, children: [
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Transform.rotate(
                  angle: _anim?.value ?? _angle,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(painter: _WheelPainter(SpinWheelCatalog.slices)),
                  ),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 38, color: context.cs.primary),
          ]),
          const SizedBox(height: 18),
          KButton(
            free
                ? tr('spin_free_btn')
                : adLeft > 0
                    ? tr('spin_ad_btn', [adLeft])
                    : tr('spin_limit_reached'),
            icon: free ? Icons.casino_rounded : Icons.play_circle_filled_rounded,
            onTap: _spinning || (!free && adLeft <= 0) ? null : () => _onSpinTap(app),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('spin_progress_title'), style: context.tt.titleMedium),
          const SizedBox(height: 12),
          for (final s in SpinWheelCatalog.slices.where((s) => s.ownable))
            Builder(builder: (_) {
              final pct = app.ownProgressOf(s.id);
              final rem = app.remainingUnlock(s.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(tr(s.labelKey), style: context.tt.titleSmall)),
                    if (pct >= 100)
                      Pill(tr('owned'), color: good)
                    else if (rem != null)
                      Pill('${_fmtRemaining(rem)} · $pct%', color: Color(s.colorValue))
                    else
                      Text('$pct%', style: context.tt.labelMedium),
                  ]),
                  const SizedBox(height: 6),
                  KProgress(pct / 100, color: Color(s.colorValue), height: 8),
                ]),
              );
            }),
        ]),
      ),
    ]);
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices);
  final List<SpinSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = (2 * pi) / slices.length;
    for (var i = 0; i < slices.length; i++) {
      final start = -pi / 2 + i * sweep;
      final paint = Paint()..color = Color(slices[i].colorValue);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, paint);
      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, border);
    }
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFF1F2937));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
