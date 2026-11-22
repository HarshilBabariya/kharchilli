import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/notifier.dart';
import '../ui/avatar.dart';
import '../ui/charts.dart';
import '../ui/effects.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'budgets.dart';
import 'capture.dart';
import 'cards.dart';
import 'export.dart';
import 'common.dart';
import 'insights.dart';
import 'reminders.dart';
import 'rewards.dart';
import 'shell.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AvatarAction _hello = AvatarAction.values[Random().nextInt(AvatarAction.values.length)];
  int _festiveReplay = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final today = Days.today();
    final month = app.inMonth(today);
    final spent = app.spentIn(today);
    final previous = app.spentIn(Days.addMonths(today, -1));
    final categories = app.byCategory(month);
    final recent = [...app.expenses]..sort((a, b) => b.day != a.day ? b.day.compareTo(a.day) : b.createdAt.compareTo(a.createdAt));
    final bills = app.upcomingReminders.take(3).toList();
    final festival = app.festival ?? app.upcomingFestival;

    final sections = <Widget>[
      _Header(action: _hello),
      if (festival != null) _FestivalBanner(festival, onReplay: () => setState(() => _festiveReplay++)),
      if (app.captures.isNotEmpty) ...[
        KCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: NavRow(icon: Icons.sms_rounded, color: const Color(0xFF26A69A), title: trPlural('capture_pending', app.captures.length), subtitle: tr('capture_review'), onTap: () => open(context, const CaptureScreen())),
        ),
        const SizedBox(height: 14),
      ],
      if (today.day <= 5 && app.inMonth(Days.addMonths(today, -1)).isNotEmpty) ...[
        KCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: NavRow(icon: Icons.auto_awesome_rounded, color: const Color(0xFFFFB300), title: tr('recap_title', [Fmt.monthYear(Days.addMonths(today, -1))]), subtitle: tr('recap_sub'), onTap: () => shareCard(context, MonthCard(Days.addMonths(today, -1)), file: 'gharcha-month', text: tr('recap_title', [Fmt.monthYear(Days.addMonths(today, -1))]))),
        ),
        const SizedBox(height: 14),
      ],
      _HeroCard(spent: spent),
      const _QuickAccess(),
      SizedBox(
        height: 118,
        child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, physics: const BouncingScrollPhysics(), children: <Widget>[
          if (app.safeToday != null)
            _Stat(icon: Icons.shield_moon_rounded, color: app.safeToday! >= 0 ? good : bad, label: app.safeToday! >= 0 ? tr('safe_today') : tr('over_today'), value: Fmt.money(app.safeToday!.abs().roundToDouble()), onTap: () => open(context, const BudgetsScreen())),
          _Stat(icon: Icons.wb_sunny_rounded, color: const Color(0xFFFF9F1C), label: tr('today'), value: Fmt.ledger(AppState.net(app.onDay(today))), onTap: () => open(context, const AddExpenseScreen(), rise: true)),
          _Stat(
            icon: spent <= previous ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: spent <= previous ? good : bad,
            label: tr('vs_last_month'),
            value: previous <= 0 ? tr('no_data_yet') : '${spent <= previous ? '-' : '+'}${((spent - previous).abs() / previous * 100).round()}%',
            onTap: () => open(context, const InsightsScreen()),
          ),
          if (s.monthlyIncome > 0)
            _Stat(icon: Icons.savings_rounded, color: good, label: tr('saved_this_month'), value: spent > s.monthlyIncome ? '-${Fmt.money(spent - s.monthlyIncome)}' : Fmt.money(s.monthlyIncome - spent), onTap: () => open(context, const BudgetsScreen())),
          _Stat(
            icon: Icons.handshake_rounded,
            color: const Color(0xFF7C4DFF),
            label: app.myGroupBalance > 0.005 ? tr('owed_to_you') : app.myGroupBalance < -0.005 ? tr('you_owe') : tr('group_balance'),
            value: app.myGroupBalance.abs() < 0.005 ? tr('nothing_pending') : Fmt.money(app.myGroupBalance.abs()),
            onTap: () => Shell.switchTab(context, 2),
          ),
          _Stat(
            icon: categories.isEmpty ? Icons.category_rounded : categories.first.key.icon,
            color: categories.isEmpty ? context.cs.tertiary : categories.first.key.tint,
            label: tr('top_category'),
            value: categories.isEmpty ? tr('nothing_logged') : categories.first.key.name,
            onTap: () => Shell.switchTab(context, 1),
          ),
        ].take(4).toList()),
      ),
      _StreakCard(),
      KCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: NavRow(icon: Icons.insights_rounded, color: const Color(0xFFEC407A), title: tr('insights'), subtitle: categories.isEmpty ? tr('insights_sub') : tr('insight_top_category', [categories.first.key.name, (categories.first.value / categories.fold(0.0, (a, b) => a + b.value) * 100).round()]), onTap: () => open(context, const InsightsScreen())),
      ),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tr('upcoming_bills'), style: context.tt.titleLarge)),
            Pressable(onTap: () => open(context, const RemindersScreen()), child: Pill(tr('manage'))),
          ]),
          const SizedBox(height: 8),
          if (bills.isEmpty) Text(tr('no_bills_hint'), style: context.tt.bodySmall),
          for (final b in bills)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                IconTile(b.key.isBill ? Icons.receipt_rounded : Icons.notifications_active_rounded, color: b.key.isBill ? const Color(0xFFFB8C00) : context.cs.primary, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.key.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                    Text(dueLabel(b.value), style: context.tt.bodySmall),
                  ]),
                ),
                if (b.key.isBill) Text(Fmt.money(b.key.amount!), style: context.tt.titleSmall),
              ]),
            ),
        ]),
      ),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tr('recent_transactions'), style: context.tt.titleLarge)),
            Pressable(onTap: () => Shell.switchTab(context, 1), child: Pill(tr('see_all'))),
          ]),
          const SizedBox(height: 6),
          if (recent.isEmpty) EmptyState(art: 'receipt', title: tr('nothing_logged'), body: tr('first_expense_hint')),
          for (final e in recent.take(5)) ExpenseTile(e),
        ]),
      ),
    ];

    return Backdrop(
      child: Stack(children: [
        SafeArea(
          bottom: false,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + MediaQuery.paddingOf(context).bottom),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => Entrance(index: i, child: sections[i]),
          ),
        ),
        if (_festiveReplay > 0 && app.festival != null)
          Positioned.fill(child: ParticleField(key: ValueKey(_festiveReplay), kind: burstFor(app.festival!.festival.pack), colours: coloursFor(app.festival!.festival.pack))),
      ]),
    );
  }
}

String dueLabel(DateTime when) {
  final days = Days.between(Days.today(), when);
  final time = Fmt.time(when.hour, when.minute);
  if (days == 0) return '${tr('due_today')} · $time';
  if (days == 1) return '${tr('due_tomorrow')} · $time';
  return tr('due_in_days', [days, Fmt.date(when)]);
}

class _Header extends StatelessWidget {
  const _Header({required this.action});
  final AvatarAction action;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Row(children: [
      Pressable(onTap: () => Shell.switchTab(context, 3), child: AvatarView(app.myLook, size: 58, animate: true, action: action)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.greeting, style: context.tt.bodySmall),
          Text(app.me?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.headlineSmall),
        ]),
      ),
      Pressable(
        onTap: () => open(context, const RewardsScreen()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: context.cs.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: context.cs.outlineVariant)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Coin(size: 18),
            const SizedBox(width: 6),
            CountUp(app.settings.points.toDouble(), style: context.tt.labelLarge!.copyWith(fontWeight: FontWeight.w700), format: (v) => Fmt.number(v)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Stack(clipBehavior: Clip.none, children: [
        RoundIcon(Icons.casino_rounded, onTap: () => open(context, const RewardsScreen(initialTab: 3))),
        if (app.canFreeSpinToday)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.cs.surface, width: 1.5),
              ),
            ),
          ),
      ]),
      const SizedBox(width: 8),
      RoundIcon(Icons.mic_rounded, filled: true, onTap: () => open(context, const AddExpenseScreen(startWithVoice: true), rise: true)),
    ]);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.spent});
  final double spent;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final budget = app.settings.monthlyBudget;
    final level = app.level;
    final progress = app.budgetProgress;
    final white70 = Colors.white.withValues(alpha: 0.78);
    return KCard(
      gradient: context.heroGradient,
      radius: 32,
      padding: const EdgeInsets.all(22),
      onTap: () => open(context, const BudgetsScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('spent_in', [Fmt.month(Days.today())]), style: TextStyle(color: white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CountUp(spent, style: context.tt.displaySmall!.copyWith(color: Colors.white))),
              const SizedBox(height: 8),
              Pill(
                budget <= 0
                    ? tr('set_budget_hint')
                    : progress > 1
                        ? tr('over_budget_by', [Fmt.money(spent - budget)])
                        : tr('left_of', [Fmt.money(budget - spent), Fmt.money(budget)]),
                onDark: true,
              ),
            ]),
          ),
          if (budget > 0) ...[
            const SizedBox(width: 12),
            RingChart(
              progress: progress,
              size: 92,
              stroke: 11,
              color: Colors.white,
              trackColor: Colors.white.withValues(alpha: 0.22),
              child: Text('${(progress * 100).round()}%', style: context.tt.titleLarge!.copyWith(color: Colors.white)),
            ),
          ],
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(moodIcon(app.mood), color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(app.moodLine, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.3))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text(tr('xp_level_label', [level.level, level.title]), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: white70, fontSize: 12, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Text(tr('xp_to_next', [level.nextAt - app.settings.lifetimePoints, level.level + 1]), maxLines: 1, style: TextStyle(color: white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        KProgress(level.progress(app.settings.lifetimePoints), color: Colors.white, track: Colors.white.withValues(alpha: 0.22), height: 8),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 148,
        child: KCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, color: color, size: 38),
            const Spacer(),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final streak = app.streak;
    final today = Days.today();
    final lastLog = app.settings.lastLogDay == 0 ? null : Days.fromKey(app.settings.lastLogDay);
    bool lit(DateTime d) => lastLog != null && streak > 0 && !d.isAfter(lastLog) && Days.between(d, lastLog) < streak;
    final next = StreakMilestones.next(streak);
    return KCard(
      onTap: () => open(context, const RewardsScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flame(size: 54, lit: streak > 0),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(streak > 0 ? tr('toast_streak', [streak]) : tr('streak_start_title'), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
              Text(streak == 0 ? tr('streak_start_body') : app.loggedToday ? tr('streak_safe') : tr('streak_at_risk'), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 6; i >= 0; i--)
            Column(children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + (6 - i) * 80),
                width: 30,
                height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: lit(DateTime(today.year, today.month, today.day - i)) ? const Color(0xFFFF8A1F) : context.cs.surfaceContainerHighest),
                child: Icon(lit(DateTime(today.year, today.month, today.day - i)) ? Icons.check_rounded : Icons.remove_rounded, size: 16, color: lit(DateTime(today.year, today.month, today.day - i)) ? Colors.white : context.cs.outlineVariant),
              ),
              const SizedBox(height: 4),
              Text(Fmt.date(DateTime(today.year, today.month, today.day - i), 'E').substring(0, 1), style: context.tt.labelSmall!.copyWith(fontSize: 10.5, color: i == 0 ? context.cs.onSurface : null)),
            ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: KProgress(streak / next, color: const Color(0xFFFF8A1F), height: 7)),
          const SizedBox(width: 10),
          Text(tr('streak_next', [next]), style: context.tt.labelSmall),
        ]),
      ]),
    );
  }
}

class _FestivalBanner extends StatelessWidget {
  const _FestivalBanner(this.day, {required this.onReplay});
  final FestivalDay day;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final f = day.festival;
    final live = app.festival?.key == day.key;
    final until = Days.between(Days.today(), day.main);
    final title = until > 0 ? trPlural('fest_countdown', until, [f.label, until]) : f.title(app.me?.name ?? '');
    final p = paletteOf(f.pack.themeId);
    return KCard(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(p.primary), Color.lerp(Color(p.primary), Color(p.secondary), 0.55)!]),
      padding: EdgeInsets.zero,
      onTap: live && app.settings.festiveMode
          ? () {
              Sfx.play(f.pack.sound);
              onReplay();
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(children: [
          if (live && app.settings.festiveMode) Positioned.fill(child: ParticleField(kind: burstFor(f.pack) == Burst.fireworks ? Burst.lights : burstFor(f.pack), colours: const [Colors.white, Color(0xFFFFE58A)], loop: true, duration: const Duration(seconds: 7))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.tt.titleLarge!.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(live ? f.line : tr('fest_upcoming_hint', [PointsRules.festivalGift]), style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.35)),
              if (live && !app.festivalClaimed) ...[
                const SizedBox(height: 12),
                Pressable(onTap: app.claimFestival, child: Pill(tr('fest_claim', [PointsRules.festivalGift]), onDark: true)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Screens the quick-access row can open: route (handled by Shell), icon, colour, label key.
const _quickActions = <(String, IconData, int, String)>[
  ('reminders', Icons.notifications_active_rounded, 0xFFFF7043, 'shortcut_bills'),
  ('shopping', Icons.shopping_cart_rounded, 0xFF43A047, 'shopping_list'),
  ('goals', Icons.flag_rounded, 0xFFFFB300, 'goals'),
  ('loans', Icons.handshake_rounded, 0xFF7C4DFF, 'loans'),
  ('budgets', Icons.pie_chart_rounded, 0xFF039BE5, 'budgets'),
  ('insights', Icons.insights_rounded, 0xFFEC407A, 'insights'),
  ('papers', Icons.description_rounded, 0xFF8D6E63, 'papers'),
  ('accounts', Icons.account_balance_wallet_rounded, 0xFF26A69A, 'accounts'),
  ('rewards', Icons.emoji_events_rounded, 0xFFFFA000, 'rewards'),
  ('voice', Icons.mic_rounded, 0xFF5C6BC0, 'shortcut_voice'),
];

/// Up to four app-icon style shortcuts the user picks.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  void _choose(BuildContext context) {
    showKSheet<void>(
      context,
      title: tr('quick_access'),
      builder: (sheet) {
        final app = AppScope.of(sheet);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('quick_access_hint', [app.settings.quickAccess.length, Settings.quickAccessMax]), style: sheet.tt.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (route, icon, color, label) in _quickActions)
              KChip(tr(label), icon: icon, color: Color(color), selected: app.settings.quickAccess.contains(route), onTap: () => app.toggleQuickAccess(route)),
          ]),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = AppScope.of(context).settings.quickAccess;
    return Column(children: [
      SectionTitle(tr('quick_access'), action: tr('a11y_edit'), onAction: () => _choose(context)),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (route, icon, color, label) in _quickActions.where((a) => picked.contains(a.$1)))
          Expanded(
            child: Pressable(
              onTap: () => Notifier.open(route),
              child: Column(children: [
                IconTile(icon, color: Color(color), size: 58),
                const SizedBox(height: 6),
                Text(tr(label), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: context.cs.onSurface)),
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 14),
    ]);
  }
}
