import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_state.dart';
import 'core/models.dart';
import 'core/notifier.dart';
import 'core/store.dart';
import 'screens/lock.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeDateFormatting();
  final app = AppState(await Store.open());
  await Notifier.init();
  await app.load();
  runApp(AppScope(state: app, child: const KharchiliApp()));
}

class KharchiliApp extends StatelessWidget {
  const KharchiliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final Widget home = !s.onboarded
        ? const OnboardingScreen()
        : app.locked
            ? const LockScreen()
            : const Shell();
    return MaterialApp(
      title: 'Kharchili',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(app.activeThemeId, Brightness.light),
      darkTheme: buildTheme(app.activeThemeId, Brightness.dark),
      themeMode: switch (s.themeMode) { ThemeModeSetting.light => ThemeMode.light, ThemeModeSetting.dark => ThemeMode.dark, ThemeModeSetting.system => ThemeMode.system },
      locale: Locale(s.language),
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Intro(child: AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey('${home.runtimeType}${s.language}'), child: home))),
    );
  }
}

/// The opening moment: the lettermark draws itself while three sparks orbit it, then the app fades in.
class Intro extends StatefulWidget {
  const Intro({super.key, required this.child});
  final Widget child;

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
    ..forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => IgnorePointer(
            ignoring: _c.value > 0.8,
            child: Opacity(
              opacity: (1 - (_c.value - 0.8) / 0.2).clamp(0.0, 1.0).toDouble(),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: RadialGradient(radius: 1.1, colors: [Color(0xFFFF4D4D), Color(0xFFE8203F), Color(0xFF8E0F45)])),
                child: Center(child: CustomPaint(size: const Size.square(230), painter: _MarkPainter(_c.value))),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.28);
    const sparks = [Color(0xFFFFC531), Color(0xFFFF9EC4), Color(0xFF6FE7DD)];
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.5 + i * 1.05);
      final rect = Rect.fromCenter(center: Offset.zero, width: size.width * 1.05, height: size.height * 0.44);
      canvas.drawOval(rect, orbit);
      final a = t * 2 * pi * (0.8 + i * 0.25) + i * 2.1;
      final p = Offset(cos(a) * rect.width / 2, sin(a) * rect.height / 2);
      canvas.drawCircle(p, 13, Paint()..color = sparks[i].withValues(alpha: 0.3));
      canvas.drawCircle(p, 7, Paint()..color = sparks[i]);
      canvas.restore();
    }
    canvas.save();
    canvas.translate(c.dx - size.width * 0.5, c.dy - size.height * 0.5);
    canvas.scale(size.width / 1024);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 112
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final parts = [
      Path()..moveTo(372, 262)..lineTo(372, 762),
      Path()..moveTo(372, 598)..cubicTo(470, 560, 560, 500, 628, 410),
      Path()..moveTo(486, 548)..cubicTo(540, 640, 590, 712, 664, 762),
    ];
    for (var i = 0; i < parts.length; i++) {
      final local = ((t - i * 0.16) / 0.3).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;
      for (final PathMetric m in parts[i].computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * Curves.easeOutCubic.transform(local)), stroke);
      }
    }
    final pop = ((t - 0.5) / 0.2).clamp(0.0, 1.0).toDouble();
    if (pop > 0) canvas.drawCircle(const Offset(726, 296), 58 * Curves.elasticOut.transform(pop), Paint()..color = const Color(0xFFFFC531));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}
