import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import 'theme.dart';

class Slice {
  const Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class RingChart extends StatelessWidget {
  const RingChart({super.key, required this.progress, this.size = 120, this.stroke = 14, this.color, this.trackColor, this.child});
  final double progress;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.cs.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => CustomPaint(
        painter: _RingPainter(v, stroke, tint, trackColor ?? context.cs.surfaceContainerHighest),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);
  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, pi * 2, false, base..color = track);
    if (value <= 0) return;
    final sweep = pi * 2 * value;
    canvas.drawArc(
      arc,
      -pi / 2,
      sweep,
      false,
      base..shader = SweepGradient(startAngle: 0, endAngle: pi * 2, transform: const GradientRotation(-pi / 2), colors: [color, Color.lerp(color, Colors.white, 0.35)!, color]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

/// Tap a bar to see its amount.
class BarChart extends StatefulWidget {
  const BarChart({super.key, required this.values, required this.labels, this.highlight, this.height = 150, this.color});
  final List<double> values;
  final List<String> labels;
  final int? highlight;
  final double height;
  final Color? color;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tint = widget.color ?? cs.primary;
    final top = widget.values.fold(0.0, max);
    final active = _picked ?? widget.highlight;
    return SizedBox(
      height: widget.height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < widget.values.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _picked = _picked == i ? null : i),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                AnimatedOpacity(
                  opacity: active == i && widget.values[i] > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: FittedBox(child: Text(Fmt.compact(widget.values[i]), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint))),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: top <= 0 ? 0.0 : max(widget.values[i], 0.0) / top),
                    duration: Duration(milliseconds: 500 + 60 * min(i, 12)),
                    curve: Curves.easeOutBack,
                    builder: (_, v, __) => FractionallySizedBox(
                      heightFactor: max(v, 0.04).clamp(0.0, 1.0).toDouble(),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: widget.values.length > 12 ? 1.5 : 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: active == i ? [Color.lerp(tint, Colors.white, 0.25)!, tint] : [tint.withValues(alpha: 0.35), tint.withValues(alpha: 0.18)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.labels[i], maxLines: 1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: active == i ? tint : cs.onSurfaceVariant)),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Running total across a period; drag across it for a bubble with that point's value.
class AreaChart extends StatefulWidget {
  const AreaChart({super.key, required this.values, this.paceTotal = 0, this.totalSlots, this.height = 150, required this.labelFor});
  final List<double> values;

  /// When above zero, a dashed straight line from 0 to this total across [totalSlots].
  final double paceTotal;
  final int? totalSlots;
  final double height;
  final String Function(int index) labelFor;

  @override
  State<AreaChart> createState() => _AreaChartState();
}

class _AreaChartState extends State<AreaChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  int? _picked;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pick(Offset local, double width) {
    final slots = widget.totalSlots ?? widget.values.length;
    if (widget.values.isEmpty || slots < 2) return;
    final i = (local.dx / width * (slots - 1)).round().clamp(0, widget.values.length - 1).toInt();
    setState(() => _picked = i);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return LayoutBuilder(
      builder: (_, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _pick(d.localPosition, box.maxWidth),
        onHorizontalDragUpdate: (d) => _pick(d.localPosition, box.maxWidth),
        onHorizontalDragEnd: (_) => setState(() => _picked = null),
        onTapUp: (_) => Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _picked = null);
        }),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size(box.maxWidth, widget.height),
            painter: _AreaPainter(
              values: widget.values,
              slots: widget.totalSlots ?? widget.values.length,
              pace: widget.paceTotal,
              reveal: Curves.easeOutCubic.transform(_c.value),
              color: cs.primary,
              muted: cs.onSurfaceVariant,
              surface: cs.surface,
              picked: _picked,
              label: _picked == null ? '' : '${widget.labelFor(_picked!)} · ${Fmt.money(widget.values[_picked!])}',
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({required this.values, required this.slots, required this.pace, required this.reveal, required this.color, required this.muted, required this.surface, required this.picked, required this.label});
  final List<double> values;
  final int slots;
  final double pace;
  final double reveal;
  final Color color;
  final Color muted;
  final Color surface;
  final int? picked;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || slots < 2) return;
    final top = max(values.fold(0.0, max), pace) * 1.12;
    if (top <= 0) return;
    Offset at(int i, double v) => Offset(size.width * i / (slots - 1), size.height - 4 - (size.height - 28) * (max(v, 0.0) / top));
    final line = Path()..moveTo(at(0, values[0]).dx, at(0, values[0]).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1, values[i - 1]), b = at(i, values[i]);
      final mid = (a.dx + b.dx) / 2;
      line.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    final last = at(values.length - 1, values.last);
    final fill = Path.from(line)
      ..lineTo(last.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));
    canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)]).createShader(Offset.zero & size));
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = color);
    canvas.restore();
    if (pace > 0) {
      final dash = Paint()
        ..color = muted.withValues(alpha: 0.6)
        ..strokeWidth = 1.6;
      final from = at(0, 0), to = at(slots - 1, pace);
      const steps = 28;
      for (var i = 0; i < steps; i += 2) {
        canvas.drawLine(Offset.lerp(from, to, i / steps)!, Offset.lerp(from, to, (i + 1) / steps)!, dash);
      }
    }
    final dot = picked == null ? last : at(picked!, values[picked!]);
    if (reveal > 0.95) {
      canvas.drawCircle(dot, 9, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(dot, 5.5, Paint()..color = surface);
      canvas.drawCircle(dot, 3.5, Paint()..color = color);
    }
    if (picked != null) {
      final text = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      final w = text.width + 18;
      final left = (dot.dx - w / 2).clamp(0.0, max(size.width - w, 0.0)).toDouble();
      final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(left, max(dot.dy - 36, 0.0), w, 24), const Radius.circular(12));
      canvas.drawRRect(bubble, Paint()..color = color);
      text.paint(canvas, Offset(left + 9, bubble.top + (24 - text.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) => true;
}

/// Tap a slice to enlarge it and read its share in the centre.
class DonutChart extends StatefulWidget {
  const DonutChart({super.key, required this.slices, this.size = 170, required this.centerLabel});
  final List<Slice> slices;
  final double size;
  final String centerLabel;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  int? _picked;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap(Offset p) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final d = p - center;
    final total = widget.slices.fold(0.0, (s, x) => s + x.value);
    if (total <= 0 || d.distance < widget.size * 0.24 || d.distance > widget.size / 2) {
      setState(() => _picked = null);
      return;
    }
    var angle = (atan2(d.dy, d.dx) + pi / 2) % (2 * pi);
    if (angle < 0) angle += 2 * pi;
    var acc = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      acc += widget.slices[i].value / total * 2 * pi;
      if (angle <= acc) {
        setState(() => _picked = _picked == i ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.slices.fold(0.0, (s, x) => s + x.value);
    final picked = _picked != null && _picked! < widget.slices.length ? widget.slices[_picked!] : null;
    return GestureDetector(
      onTapUp: (d) => _tap(d.localPosition),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => CustomPaint(
          painter: _DonutPainter(widget.slices, total, Curves.easeOutCubic.transform(_c.value), _picked, context.cs.surfaceContainerHighest),
          child: child,
        ),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(picked?.label ?? widget.centerLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall),
                FittedBox(child: Text(Fmt.money(picked?.value ?? total), style: context.tt.titleLarge)),
                if (picked != null && total > 0) Text('${(picked.value / total * 100).round()}%', style: context.tt.labelMedium!.copyWith(color: picked.color)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.total, this.reveal, this.picked, this.track);
  final List<Slice> slices;
  final double total;
  final double reveal;
  final int? picked;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.15;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    if (total <= 0) {
      canvas.drawArc(rect, 0, 2 * pi, false, paint..color = track..strokeWidth = stroke);
      return;
    }
    var start = -pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].value / total * 2 * pi * reveal;
      final gap = slices.length > 1 ? 0.03 : 0.0;
      canvas.drawArc(rect, start + gap / 2, max(sweep - gap, 0.001), false, paint..color = slices[i].color..strokeWidth = picked == i ? stroke + 8 : stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

class SplitBar extends StatelessWidget {
  const SplitBar(this.slices, {super.key, this.height = 14});
  final List<Slice> slices;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold(0.0, (s, x) => s + x.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(children: [
          if (total <= 0) Expanded(child: ColoredBox(color: context.cs.surfaceContainerHighest)),
          for (final s in slices)
            if (s.value > 0) Expanded(flex: max((s.value / total * 1000).round(), 1), child: Container(margin: const EdgeInsets.only(right: 2), color: s.color)),
        ]),
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow(this.slice, this.total, {super.key, this.trailing});
  final Slice slice;
  final double total;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0 : (slice.value / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(slice.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.bodyMedium)),
        if (trailing != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(trailing!, style: context.tt.labelSmall)),
        Text('$share% · ${Fmt.money(slice.value)}', style: context.tt.labelMedium!.copyWith(color: context.cs.onSurface)),
      ]),
    );
  }
}
