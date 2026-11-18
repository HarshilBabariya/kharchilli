import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/effects.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;
  Gender _gender = Gender.male;
  String _currency = 'INR';
  double _budget = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => _page != 1 || _name.text.trim().isNotEmpty;

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_page < 2) {
      _pages.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      return;
    }
    setState(() => _busy = true);
    await AppScope.read(context).completeOnboarding(name: _name.text, gender: _gender, currency: _currency, budget: _budget);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    return Scaffold(
      body: Backdrop(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: SizedBox(
                height: 48,
                child: Row(children: [
                AnimatedOpacity(
                  opacity: _page > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(ignoring: _page == 0, child: RoundIcon(Icons.arrow_back_rounded, onTap: () => _pages.previousPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic))),
                ),
                const Spacer(),
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.only(left: 6),
                    width: _page == i ? 28 : 9,
                    height: 9,
                    decoration: BoxDecoration(color: _page >= i ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(9)),
                  ),
              ]),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [_welcome(app), _you(), _money()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: KButton(_page == 2 ? tr('get_started') : tr('continue_'), icon: _page == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, onTap: _canContinue && !_busy ? _next : null),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _welcome(AppState app) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 12),
      SizedBox(
        height: 220,
        child: Stack(alignment: Alignment.center, children: [
          const Positioned.fill(child: ParticleField(kind: Burst.lights, loop: true, duration: Duration(seconds: 9))),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: Transform.rotate(angle: (1 - v) * -0.5, child: child)),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: context.cs.primary.withValues(alpha: 0.45), blurRadius: 40, offset: const Offset(0, 18))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(40), child: Image.asset('assets/brand/icon.png', width: 150, height: 150)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      Entrance(index: 2, child: Text(tr('welcome_title'), textAlign: TextAlign.center, style: context.tt.headlineMedium)),
      const SizedBox(height: 10),
      Entrance(index: 3, child: Text(tr('welcome_body'), textAlign: TextAlign.center, style: context.tt.bodyLarge!.copyWith(color: context.cs.onSurfaceVariant))),
      const SizedBox(height: 28),
      Entrance(
        index: 4,
        child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          for (final l in L10n.languages.entries) KChip(l.value, icon: Icons.translate_rounded, selected: app.settings.language == l.key, onTap: () => app.setLanguage(l.key)),
        ]),
      ),
    ]);
  }

  Widget _you() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Center(child: AvatarView(AvatarConfig(gender: _gender, hairId: _gender == Gender.male ? 'hair_short' : 'hair_long', mood: Mood.happy), size: 170, animate: true, action: AvatarAction.wave)),
      const SizedBox(height: 18),
      Text(_name.text.trim().isEmpty ? tr('your_name') : tr('hi_name', [_name.text.trim().capitalised]), textAlign: TextAlign.center, style: context.tt.headlineSmall),
      const SizedBox(height: 22),
      KField(controller: _name, label: tr('your_name'), hint: tr('your_name_hint'), onChanged: (_) => setState(() {})),
      const SizedBox(height: 18),
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 7), child: Text(tr('gender'), style: context.tt.labelMedium)),
      Segmented<Gender>(options: {for (final g in Gender.values) g: tr('gender_${g.name}')}, value: _gender, onChanged: (g) => setState(() => _gender = g)),
    ]);
  }

  Widget _money() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Center(child: Sticker('forecast', size: 104)),
      const SizedBox(height: 22),
      Text(tr('money_setup'), textAlign: TextAlign.center, style: context.tt.headlineMedium),
      const SizedBox(height: 8),
      Text(tr('money_setup_body'), textAlign: TextAlign.center, style: context.tt.bodyMedium!.copyWith(color: context.cs.onSurfaceVariant)),
      const SizedBox(height: 26),
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 7), child: Text(tr('currency'), style: context.tt.labelMedium)),
      Segmented<String>(
        options: {for (final c in currencies.entries) c.key: '${c.value}  ${c.key}'},
        value: _currency,
        onChanged: (code) => setState(() {
          _currency = code;
          Fmt.symbol = currencies[code]!;
          Fmt.currencyCode = code;
        }),
      ),
      const SizedBox(height: 22),
      KCard(
        onTap: () async {
          final v = await askAmount(context, title: tr('monthly_budget_optional'), initial: _budget, removeLabel: tr('remove_limit'));
          if (v != null) setState(() => _budget = v);
        },
        child: Row(children: [
          const IconTile(Icons.savings_rounded, color: Color(0xFF22A861)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('monthly_budget_optional'), style: context.tt.labelSmall),
              Text(_budget > 0 ? Fmt.money(_budget) : tr('tap_to_set_limit'), style: context.tt.titleLarge),
            ]),
          ),
          Icon(Icons.edit_rounded, color: context.cs.onSurfaceVariant),
        ]),
      ),
    ]);
  }
}
