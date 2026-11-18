import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_state.dart';
import 'core/l10n.dart';
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
  runApp(AppScope(state: app, child: const GharchaApp()));
}

class GharchaApp extends StatelessWidget {
  const GharchaApp({super.key});

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
      title: 'Gharcha',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(app.activeThemeId, Brightness.light),
      darkTheme: buildTheme(app.activeThemeId, Brightness.dark),
      themeMode: switch (s.themeMode) { ThemeModeSetting.light => ThemeMode.light, ThemeModeSetting.dark => ThemeMode.dark, ThemeModeSetting.system => ThemeMode.system },
      locale: Locale(s.language),
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          statusBarIconBrightness: context.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness: context.isDark ? Brightness.light : Brightness.dark,
        ),
        child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
      ),
      home: Intro(child: AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey('${home.runtimeType}${s.language}'), child: home))),
    );
  }
}

/// The opening moment: the house rises, three coins drop into it, the rupee writes itself and the name arrives.
class Intro extends StatefulWidget {
  const Intro({super.key, required this.child});
  final Widget child;

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
    ..forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _phase(double from, double length) => ((_c.value - from) / length).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    const white = TextStyle(fontFamily: 'Poppins', color: Colors.white, decoration: TextDecoration.none);
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => IgnorePointer(
            ignoring: _c.value > 0.86,
            child: Opacity(
              opacity: 1 - _phase(0.86, 0.14),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF5A5A), Color(0xFFE8203F), Color(0xFFA3123F)])),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CustomPaint(size: const Size.square(230), painter: _MarkPainter(_c.value)),
                  Transform.translate(
                    offset: Offset(0, 18 * (1 - Curves.easeOutCubic.transform(_phase(0.56, 0.2)))),
                    child: Opacity(opacity: _phase(0.56, 0.2), child: Text('Gharcha', style: white.copyWith(fontWeight: FontWeight.w700, fontSize: 40, letterSpacing: -0.5))),
                  ),
                  const SizedBox(height: 2),
                  Opacity(opacity: _phase(0.66, 0.2) * 0.85, child: Text(tr('tagline'), style: white.copyWith(fontWeight: FontWeight.w500, fontSize: 15))),
                ]),
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

  static const _gold = Color(0xFFFFC531);

  double _phase(double from, double length) => ((t - from) / length).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    final rise = Curves.easeOutBack.transform(_phase(0, 0.26));
    var bump = 0.0;
    for (var i = 0; i < 3; i++) {
      bump += sin(_phase(0.38 + i * 0.09, 0.1) * pi) * 16;
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(512, 870), width: 520 * rise, height: 44 * rise), Paint()..color = Colors.black.withValues(alpha: 0.16));

    for (var i = 0; i < 3; i++) {
      final fall = _phase(0.2 + i * 0.09, 0.18);
      if (fall <= 0 || fall >= 1) continue;
      final drop = Curves.easeIn.transform(fall);
      final at = Offset(512 + (i - 1) * 150 * (1 - drop), -140 + 520 * drop);
      final r = 62 * (1 - 0.35 * drop);
      canvas.drawCircle(at, r, Paint()..color = _gold);
      canvas.drawCircle(at, r * 0.7, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..color = const Color(0xFFFFE9A6));
    }

    canvas.save();
    canvas.translate(512, 788 + (1 - rise) * 420 + bump);
    canvas.scale(1 + bump / 420, rise * (1 - bump / 300));
    canvas.translate(-512, -788);
    final house = Path()
      ..moveTo(512, 236)
      ..lineTo(792, 468)
      ..lineTo(792, 716)
      ..quadraticBezierTo(792, 788, 720, 788)
      ..lineTo(304, 788)
      ..quadraticBezierTo(232, 788, 232, 716)
      ..lineTo(232, 468)
      ..close();
    canvas.drawPath(house, Paint()..color = Colors.white);
    canvas.drawPath(house, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 72
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 54
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE8203F);
    final parts = [
      Path()..moveTo(410, 452)..lineTo(614, 452),
      Path()..moveTo(410, 540)..lineTo(614, 540),
      Path()..moveTo(410, 452)..lineTo(486, 452)..quadraticBezierTo(576, 452, 576, 540)..quadraticBezierTo(576, 628, 486, 628)..lineTo(410, 628)..lineTo(560, 760),
    ];
    for (var i = 0; i < parts.length; i++) {
      final drawn = _phase(0.5 + i * 0.07, 0.2);
      if (drawn <= 0) continue;
      for (final PathMetric m in parts[i].computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * Curves.easeOutCubic.transform(drawn)), stroke);
      }
    }
    canvas.restore();

    final pop = _phase(0.66, 0.2);
    if (pop > 0) canvas.drawCircle(const Offset(770, 268), 58 * Curves.elasticOut.transform(pop), Paint()..color = _gold);
    for (final (i, at) in const [Offset(150, 380), Offset(880, 560), Offset(250, 180)].indexed) {
      final glint = sin(_phase(0.6 + i * 0.07, 0.24) * pi);
      if (glint <= 0) continue;
      final r = 40 * glint;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - r)
          ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
          ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
          ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
          ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}
