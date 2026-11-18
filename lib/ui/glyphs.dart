import 'dart:math';

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

/// One of the illustrated sticker icons in assets/art/icons (drawn by tool/make_art.py).
class Sticker extends StatelessWidget {
  const Sticker(this.name, {super.key, this.size = 52});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset('assets/art/icons/$name.png', width: size, height: size, filterQuality: FilterQuality.medium, excludeFromSemantics: true);
}

/// The points coin.
class Coin extends StatelessWidget {
  const Coin({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE58A), Color(0xFFFFB627), Color(0xFFE08A00)]),
        border: Border.all(color: const Color(0xFFFFF3C4), width: size * 0.07),
      ),
      child: Icon(Icons.star_rounded, color: Colors.white, size: size * 0.68),
    );
  }
}

const _grey = ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);

/// A badge's medal from assets/art/badges. A locked medal is greyed out behind a padlock, with a ring showing progress.
class Medal extends StatelessWidget {
  const Medal(this.badgeId, {super.key, this.size = 72, this.locked = false, this.progress = 1});
  final String badgeId;
  final double size;
  final bool locked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final art = Image.asset('assets/art/badges/$badgeId.png', width: size, height: size * 1.18, filterQuality: FilterQuality.medium, excludeFromSemantics: true);
    if (!locked) return art;
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: Stack(children: [
        Opacity(opacity: context.isDark ? 0.5 : 0.6, child: ColorFiltered(colorFilter: _grey, child: art)),
        Positioned(
          left: size * 0.2,
          top: size * 0.18,
          width: size * 0.6,
          height: size * 0.6,
          child: CustomPaint(
            painter: _ProgressPainter(progress, context.cs.primary, size * 0.055),
            child: Center(
              child: Container(
                width: size * 0.36,
                height: size * 0.36,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, color: Colors.white, size: size * 0.2),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.progress, this.color, this.stroke);
  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.drawArc((Offset.zero & size).deflate(stroke / 2), -pi / 2, 2 * pi * progress.clamp(0.0, 1.0).toDouble(), false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color);
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.progress != progress || old.color != color;
}

/// Keys a group can pick its sticker from: `group_<key>` in assets/art/icons.
const groupIcons = ['home', 'trip', 'party', 'food', 'beach', 'shop', 'ride', 'study'];

/// Keys a household service can carry: `svc_<key>` in assets/art/icons.
const serviceIcons = ['milk', 'paper', 'water', 'maid', 'cook', 'driver', 'other'];

Widget groupSticker(String key, {double size = 52}) => Sticker('group_${groupIcons.contains(key) ? key : groupIcons.first}', size: size);

Widget serviceSticker(String key, {double size = 52}) => Sticker('svc_${serviceIcons.contains(key) ? key : serviceIcons.last}', size: size);

IconData moodIcon(Mood mood) => switch (mood) {
      Mood.happy => Icons.sentiment_very_satisfied_rounded,
      Mood.love => Icons.favorite_rounded,
      Mood.excited => Icons.celebration_rounded,
      Mood.smart => Icons.psychology_rounded,
      Mood.neutral => Icons.sentiment_neutral_rounded,
      Mood.confused => Icons.help_rounded,
      Mood.sleepy => Icons.bedtime_rounded,
      Mood.sad => Icons.sentiment_dissatisfied_rounded,
      Mood.worried => Icons.warning_amber_rounded,
      Mood.angry => Icons.mood_bad_rounded,
    };

IconData actionIcon(AvatarAction action) => switch (action) {
      AvatarAction.wave => Icons.waving_hand_rounded,
      AvatarAction.jump => Icons.keyboard_double_arrow_up_rounded,
      AvatarAction.spin => Icons.autorenew_rounded,
      AvatarAction.dance => Icons.music_note_rounded,
      AvatarAction.wink => Icons.auto_awesome_rounded,
      AvatarAction.cheer => Icons.celebration_rounded,
      AvatarAction.laugh => Icons.sentiment_very_satisfied_rounded,
    };

/// A miniature home screen painted in a theme's own colours.
class ThemePreview extends StatelessWidget {
  const ThemePreview(this.themeId, {super.key, this.height = 92});
  final String themeId;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(themeId);
    final dark = context.isDark;
    final surface = dark ? Color(p.darkSurface) : Colors.white;
    final ink = (dark ? Colors.white : Colors.black).withValues(alpha: 0.14);
    Widget bar(double width, Color color) => Container(width: width, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Color(dark ? p.darkBg : p.lightBg), borderRadius: BorderRadius.circular(16), border: Border.all(color: ink)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(Color(p.primary), Color(p.secondary), 0.25)!, Color(p.primary)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [bar(26, Colors.white70), const SizedBox(height: 5), bar(48, Colors.white)]),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          flex: 3,
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(p.tertiary), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  bar(28, ink),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            AspectRatio(aspectRatio: 1, child: DecoratedBox(decoration: BoxDecoration(color: Color(p.secondary), shape: BoxShape.circle))),
          ]),
        ),
      ]),
    );
  }
}
