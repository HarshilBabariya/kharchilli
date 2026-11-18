import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/l10n.dart';
import 'glyphs.dart';
import 'theme.dart';

/// Shrinks under the finger and springs back: every tappable surface uses it.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap != null || widget.onLongPress != null) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: Duration(milliseconds: _down ? 90 : 260), curve: _down ? Curves.easeOut : Curves.elasticOut, child: widget.child),
    );
  }
}

/// Fades and slides its child in; [index] staggers siblings.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0, this.offset = 26});
  final Widget child;
  final int index;
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * min(widget.index, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, child) => Opacity(opacity: curve.value, child: Transform.translate(offset: Offset(0, widget.offset * (1 - curve.value)), child: child)),
      child: widget.child,
    );
  }
}

class KCard extends StatelessWidget {
  const KCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap, this.gradient, this.color, this.radius = 26});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color ?? cs.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: gradient == null ? Border.all(color: cs.outlineVariant) : null,
        boxShadow: [
          BoxShadow(color: (gradient == null ? Colors.black : cs.primary).withValues(alpha: gradient == null ? (context.isDark ? 0.25 : 0.05) : 0.32), blurRadius: gradient == null ? 18 : 28, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, scale: 0.98, child: box);
  }
}

/// A glossy gradient tile with a white icon: categories, rows and anything else without its own sticker.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color, this.size = 44});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.cs.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(tint, Colors.white, 0.32)!, tint, Color.lerp(tint, Colors.black, 0.22)!]),
        boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.3), blurRadius: size * 0.2, offset: Offset(0, size * 0.08))],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
          top: size * 0.06,
          left: size * 0.1,
          right: size * 0.1,
          height: size * 0.38,
          child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.26), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.34), Colors.white.withValues(alpha: 0)]))),
        ),
        Icon(icon, color: Colors.white, size: size * 0.54),
      ]),
    );
  }
}

/// The main button. While an async [onTap] is running it ignores further taps, so nothing is saved twice.
class KButton extends StatefulWidget {
  const KButton(this.label, {super.key, this.onTap, this.icon, this.tonal = false, this.expand = true, this.danger = false});
  final String label;
  final FutureOr<void> Function()? onTap;
  final IconData? icon;
  final bool tonal;
  final bool expand;
  final bool danger;

  @override
  State<KButton> createState() => _KButtonState();
}

class _KButtonState extends State<KButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onTap!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final enabled = widget.onTap != null;
    final tonal = widget.tonal, danger = widget.danger;
    final fg = tonal ? (danger ? cs.error : cs.onPrimaryContainer) : Colors.white;
    return Pressable(
      onTap: enabled ? _run : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 56,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: tonal ? null : (danger ? const LinearGradient(colors: [Color(0xFFE5484D), Color(0xFFB3261E)]) : context.heroGradient),
            color: tonal ? (danger ? cs.error.withValues(alpha: 0.12) : cs.primaryContainer) : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: tonal || !enabled ? null : [BoxShadow(color: (danger ? cs.error : cs.primary).withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_busy)
              Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg)))
            else if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelLarge!.copyWith(color: fg, fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
        ),
      ),
    );
  }
}

/// One choice out of a few, as a sliding pill.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.color});
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        for (final option in options.entries)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(option.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == option.key ? (color ?? cs.primary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: value == option.key ? [BoxShadow(color: (color ?? cs.primary).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(option.value, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: value == option.key ? Colors.white : cs.onSurfaceVariant))),
              ),
            ),
          ),
      ]),
    );
  }
}

class KChip extends StatelessWidget {
  const KChip(this.label, {super.key, required this.selected, required this.onTap, this.icon, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tint = color ?? cs.primary;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: selected ? tint : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: selected ? Colors.white : cs.onSurfaceVariant), const SizedBox(width: 6)],
          Text(label, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: selected ? Colors.white : cs.onSurface)),
        ]),
      ),
    );
  }
}

/// Counts from the previous value to [value] whenever it changes.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, required this.style, this.format});
  final double value;
  final TextStyle style;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text((format ?? Fmt.money)(v.roundToDouble()), maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}

class KProgress extends StatelessWidget {
  const KProgress(this.value, {super.key, this.color, this.height = 10, this.track});
  final double value;
  final Color? color;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.cs.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track ?? context.cs.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(height), gradient: LinearGradient(colors: [tint, Color.lerp(tint, Colors.white, 0.3)!]))),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: context.tt.titleLarge)),
        if (action != null) Pressable(onTap: onAction, child: Text(action!, style: context.tt.labelLarge!.copyWith(color: context.cs.primary))),
      ]),
    );
  }
}

class EmptyState extends StatefulWidget {
  const EmptyState({super.key, required this.art, required this.title, required this.body});

  /// A sticker name from assets/art/icons.
  final String art;
  final String title;
  final String body;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.translate(offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)), child: Transform.rotate(angle: -0.08 + 0.16 * Curves.easeInOut.transform(_c.value), child: child)),
          child: Sticker(widget.art, size: 96),
        ),
        const SizedBox(height: 20),
        Text(widget.title, textAlign: TextAlign.center, style: context.tt.titleLarge),
        const SizedBox(height: 6),
        Text(widget.body, textAlign: TextAlign.center, style: context.tt.bodyMedium!.copyWith(color: context.cs.onSurfaceVariant)),
      ]),
    );
  }
}

/// Soft colour glows behind every screen, tinted by the active theme.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    Widget glow(Alignment at, Color color, double size) => Align(
          alignment: at,
          child: IgnorePointer(
            child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: context.isDark ? 0.22 : 0.16), color.withValues(alpha: 0)]))),
          ),
        );
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)),
      glow(const Alignment(-1.6, -1.25), cs.primary, 420),
      glow(const Alignment(1.8, -0.5), cs.secondary, 360),
      glow(const Alignment(-1.4, 1.2), cs.tertiary, 380),
      child,
    ]);
  }
}

class KPage extends StatelessWidget {
  const KPage({super.key, required this.title, required this.children, this.actions = const [], this.bottom, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  /// A button pinned above the bottom edge.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final pushed = !(ModalRoute.of(context)?.isFirst ?? true);
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final clearance = bottom != null ? 100.0 : (pushed ? 24.0 : navBarHeight + 24);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Backdrop(
        child: Stack(children: [
          SafeArea(
            bottom: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: SizedBox(
                  height: 52,
                  child: Row(children: [
                    if (pushed) ...[RoundIcon(Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()), const SizedBox(width: 12)],
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: pushed ? context.tt.headlineSmall : context.tt.headlineMedium),
                        if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
                      ]),
                    ),
                    for (final a in actions) Padding(padding: const EdgeInsets.only(left: 8), child: a),
                  ]),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, clearance + inset),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  children: [for (var i = 0; i < children.length; i++) Entrance(index: i, child: children[i])],
                ),
              ),
            ]),
          ),
          if (bottom != null) Positioned(left: 20, right: 20, bottom: inset + 16, child: bottom!),
        ]),
      ),
    );
  }
}

/// Height of the tab bar, so tab pages can keep their last card clear of it.
const navBarHeight = 78.0;

class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: filled ? cs.primary : cs.surface, shape: BoxShape.circle, border: filled ? null : Border.all(color: cs.outlineVariant)),
        child: Icon(icon, size: 22, color: filled ? Colors.white : cs.onSurface),
      ),
    );
  }
}

class NavRow extends StatelessWidget {
  const NavRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.trailing, this.color});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          IconTile(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
              if (subtitle != null) Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
            ]),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: context.cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class KSwitch extends StatelessWidget {
  const KSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Pressable(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: value ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))])),
        ),
      ),
    );
  }
}

/// A text field with its label above it.
class KField extends StatelessWidget {
  const KField({super.key, required this.controller, required this.label, this.hint, this.number = false, this.onChanged, this.onTap, this.autofocus = false, this.icon, this.lines = 1});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool number;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final IconData? icon;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 7), child: Text(label, style: context.tt.labelMedium)),
      TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onTap: onTap,
        minLines: 1,
        maxLines: lines,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
        textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint, prefixIcon: icon == null ? null : Icon(icon)),
      ),
    ]);
  }
}

/// A bottom sheet that closes with its X button or a tap outside, never by a drag on its content.
Future<T?> showKSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + max(MediaQuery.viewInsetsOf(sheet).bottom, MediaQuery.viewPaddingOf(sheet).bottom)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: sheet.tt.titleLarge)),
          RoundIcon(Icons.close_rounded, onTap: () => Navigator.of(sheet).pop()),
        ]),
        const SizedBox(height: 16),
        Flexible(child: SingleChildScrollView(child: builder(sheet))),
      ]),
    ),
  );
}

Future<bool> confirm(BuildContext context, {required String title, required String body, required String action, bool danger = true}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title, style: d.tt.titleLarge),
      content: Text(body),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(children: [
          Expanded(child: KButton(tr('cancel'), tonal: true, onTap: () => Navigator.of(d).pop(false))),
          const SizedBox(width: 10),
          Expanded(child: KButton(action, danger: danger, onTap: () => Navigator.of(d).pop(true))),
        ]),
      ],
    ),
  );
  return ok ?? false;
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}

/// The big number pad used wherever money is typed.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  void _press(String key) {
    HapticFeedback.lightImpact();
    if (key == '⌫') {
      onChanged(value.isEmpty ? '' : value.substring(0, value.length - 1));
    } else if (key == '.') {
      if (!value.contains('.')) onChanged(value.isEmpty ? '0.' : '$value.');
    } else {
      final decimals = value.contains('.') ? value.split('.').last.length : 0;
      if (decimals < 2 && value.replaceAll('.', '').length < 9) onChanged(value == '0' ? key : '$value$key');
    }
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final k in keys)
          Pressable(
            scale: 0.86,
            onTap: () => _press(k),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: context.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
              child: k == '⌫' ? Icon(Icons.backspace_rounded, color: context.cs.onSurface) : Text(k, style: context.tt.headlineSmall),
            ),
          ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.onDark = false, this.icon});
  final String text;
  final Color? color;
  final bool onDark;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: onDark ? Colors.white.withValues(alpha: 0.2) : tint.withValues(alpha: context.isDark ? 0.24 : 0.13), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[icon!, const SizedBox(width: 5)],
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: onDark ? Colors.white : (context.isDark ? Color.lerp(tint, Colors.white, 0.35) : tint)))),
      ]),
    );
  }
}

/// Pushes [page]; [rise] slides it up from the bottom like a sheet taking over the screen.
Future<T?> open<T>(BuildContext context, Widget page, {bool rise = false}) {
  if (!rise) return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));
  return Navigator.of(context).push<T>(PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curve), child: FadeTransition(opacity: curve, child: child));
    },
  ));
}
