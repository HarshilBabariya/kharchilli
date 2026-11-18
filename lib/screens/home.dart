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
import 'common.dart';
import 'export.dart';
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
    final week = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i)];
    final weekTotals = [for (final d in week) max(AppState.net(app.onDay(d)), 0.0)];
    final categories = app.byCategory(month);
    final payers = app.byPayer(month);
    final recent = [...app.expenses]..sort((a, b) => b.day != a.day ? b.day.compareTo(a.day) : b.createdAt.compareTo(a.createdAt));
    final bills = app.upcomingReminders.take(3).toList();
    final festival = app.festival ?? app.upcomingFestival;
    var running = 0.0;
    final cumulative = [
      for (var d = 1; d <= today.day; d++) running = max(running + AppState.net(app.onDay(DateTime(today.year, today.month, d))), 0.0),
    ];

    final sections = <Widget>[
      _Header(action: _hello),
      if (festival != null) _FestivalBanner(festival, onReplay: () => setState(() => _festiveReplay++)),
      _HeroCard(spent: spent),
      SizedBox(
        height: 118,
        child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, physics: const BouncingScrollPhysics(), children: [
          _Stat(icon: Icons.wb_sunny_rounded, color: const Color(0xFFFF9F1C), label: tr('today'), value: Fmt.ledger(AppState.net(app.onDay(today))), onTap: () => open(context, const AddExpenseScreen(), rise: true)),
          _Stat(
            icon: spent <= previous ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: spent <= previous ? good : bad,
            label: tr('vs_last_month'),
            value: previous <= 0 ? tr('no_data_yet') : '${spent <= previous ? '-' : '+'}${((spent - previous).abs() / previous * 100).round()}%',
            onTap: () => open(context, const InsightsScreen()),
          ),
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
        ]),
      ),
      _StreakCard(),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('month_so_far'), style: context.tt.titleLarge),
          const SizedBox(height: 2),
          Text('${tr('on_pace_for')} · ${Fmt.money(app.projectedMonth)}', style: context.tt.bodySmall),
          const SizedBox(height: 14),
          AreaChart(values: cumulative, paceTotal: s.monthlyBudget, totalSlots: Days.inMonth(today), labelFor: (i) => Fmt.date(DateTime(today.year, today.month, i + 1))),
          if (app.forecast != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [Icon(Icons.auto_graph_rounded, size: 22, color: context.cs.primary), const SizedBox(width: 10), Expanded(child: Text(app.forecast!, style: context.tt.bodyMedium))]),
            ),
          ],
        ]),
      ),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('last_7_days'), style: context.tt.titleLarge),
                Text('${Fmt.money(weekTotals.fold(0.0, (a, b) => a + b))} · ${tr('avg_per_day', [Fmt.money(weekTotals.fold(0.0, (a, b) => a + b) / 7)])}', style: context.tt.bodySmall),
              ]),
            ),
            RoundIcon(Icons.ios_share_rounded, onTap: () => shareWeeklyCard(context)),
          ]),
          const SizedBox(height: 12),
          BarChart(values: weekTotals, labels: [for (final d in week) Fmt.date(d, 'E').substring(0, 1)], highlight: 6),
        ]),
      ),
      if (categories.isNotEmpty)
        KCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(tr('by_category'), style: context.tt.titleLarge)),
              if (app.isUnlocked(RewardCatalog.insights)) Pressable(onTap: () => open(context, const InsightsScreen()), child: Pill(tr('insights'))),
            ]),
            const SizedBox(height: 10),
            Center(child: DonutChart(slices: [for (final c in categories) Slice(c.key.name, c.value, c.key.tint)], centerLabel: Fmt.month(today))),
            const SizedBox(height: 8),
            for (final c in categories.take(5)) LegendRow(Slice(c.key.name, c.value, c.key.tint), categories.fold(0.0, (a, b) => a + b.value)),
          ]),
        ),
      if (payers.length > 1)
        KCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('who_paid'), style: context.tt.titleLarge),
            const SizedBox(height: 10),
            for (final p in payers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  AvatarView(p.key.avatar, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(p.key.name, style: context.tt.titleSmall)), Text(Fmt.money(p.value), style: context.tt.titleSmall)]),
                      const SizedBox(height: 6),
                      KProgress(p.value / payers.fold(0.0, (a, b) => a + b.value), height: 7),
                    ]),
                  ),
                ]),
              ),
          ]),
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
                    Text(b.key.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
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
            padding: EdgeInsets.fromLTRB(20, 10, 20, navBarHeight + 24 + MediaQuery.viewPaddingOf(context).bottom),
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
