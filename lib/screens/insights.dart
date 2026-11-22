import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/charts.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';
import 'export.dart';
import 'rewards.dart';

enum _Period { week, month, year }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _Period _period = _Period.month;
  int _back = 0;

  (DateTime, DateTime) _range(int back) {
    final t = Days.today();
    switch (_period) {
      case _Period.week:
        final start = DateTime(t.year, t.month, t.day - (t.weekday - 1) - 7 * back);
        return (start, DateTime(start.year, start.month, start.day + 6));
      case _Period.month:
        final start = DateTime(t.year, t.month - back);
        return (start, DateTime(start.year, start.month + 1, 0));
      case _Period.year:
        return (DateTime(t.year - back), DateTime(t.year - back, 12, 31));
    }
  }

  String _label(DateTime from, DateTime to) => switch (_period) {
        _Period.week => '${Fmt.date(from)} – ${Fmt.date(to)}',
        _Period.month => Fmt.monthYear(from),
        _Period.year => '${from.year}',
      };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final advanced = app.isUnlocked(RewardCatalog.insights);
    final (from, to) = _range(_back);
    final (prevFrom, prevTo) = _range(_back + 1);
    final list = app.between(from, to);
    final before = app.between(prevFrom, prevTo);
    final total = max(AppState.net(list), 0.0), last = max(AppState.net(before), 0.0);
    final today = Days.today();
    final elapsed = max(Days.between(from, to.isAfter(today) ? today : to) + 1, 1);
    final spends = list.where((e) => e.amount > 0).toList();
    final categories = app.byCategory(list);
    final categoryTotal = categories.fold(0.0, (a, b) => a + b.value);
    final previousByCategory = {for (final c in app.byCategory(before)) c.key.key: c.value};
    final modes = [for (final m in PaymentMode.values) Slice(m.label, max(AppState.net(list.where((e) => e.mode == m)), 0.0), m.color)];
    final payers = app.byPayer(list);
    final change = last <= 0 ? null : (total - last) / last * 100;

    final List<double> series;
    final List<String> labels;
    if (_period == _Period.year) {
      series = [for (var m = 1; m <= 12; m++) max(AppState.net(list.where((e) => e.date.month == m)), 0.0)];
      labels = [for (var m = 1; m <= 12; m++) Fmt.date(DateTime(from.year, m), 'MMM').substring(0, 1)];
    } else {
      final count = Days.between(from, to) + 1;
      series = [for (var i = 0; i < count; i++) max(AppState.net(app.onDay(DateTime(from.year, from.month, from.day + i))), 0.0)];
      labels = [for (var i = 0; i < count; i++) Fmt.date(DateTime(from.year, from.month, from.day + i), 'E').substring(0, 1)];
    }
    final busiest = series.indexOf(series.fold(0.0, max));
    var running = 0.0;
    final cumulative = [for (final v in series.take(_back == 0 && _period == _Period.month ? today.day : series.length)) running += v];

    return KPage(
      title: tr('insights'),
      actions: [RoundIcon(Icons.ios_share_rounded, onTap: () => shareWeeklyCard(context))],
      children: [
        if (advanced) ...[
        Segmented<_Period>(
          options: {for (final p in _Period.values) p: tr('period_${p.name}')},
          value: _period,
          onChanged: (p) => setState(() {
            _period = p;
            _back = 0;
          }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          RoundIcon(Icons.chevron_left_rounded, onTap: () => setState(() => _back++)),
          Expanded(
            child: Column(children: [
              Text(_label(from, to), style: context.tt.titleMedium),
              Text(tr('n_transactions', [list.length]), style: context.tt.bodySmall),
            ]),
          ),
          Opacity(opacity: _back == 0 ? 0.3 : 1, child: RoundIcon(Icons.chevron_right_rounded, onTap: () => setState(() => _back = max(_back - 1, 0)))),
        ]),
        const SizedBox(height: 14),
        ],
        KCard(
          key: ValueKey('hero$_period$_back'),
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('spending'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CountUp(total, style: context.tt.displaySmall!.copyWith(color: Colors.white))),
            if (change != null) Padding(padding: const EdgeInsets.only(top: 4), child: Pill(tr(change >= 0 ? 'change_up' : 'change_down', [change.abs().round()]), onDark: true)),
            const SizedBox(height: 14),
            Row(children: [
              _Mini(tr('daily_average'), Fmt.money(total / elapsed)),
              _Mini(tr('transactions'), '${list.length}'),
              _Mini(tr('biggest'), spends.isEmpty ? '—' : Fmt.money(spends.fold(0.0, (m, e) => max(m, e.amount)))),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        KCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Sticker('idea', size: 44),
            const SizedBox(width: 12),
            Expanded(child: Text(categories.isEmpty ? tr('insight_quiet') : tr('insight_top_category', [categories.first.key.name, (categories.first.value / categoryTotal * 100).round()]), style: context.tt.bodyMedium)),
          ]),
        ),
        SectionTitle(tr('spending_trend')),
        KCard(
          key: ValueKey('trend$_period$_back'),
          child: _period == _Period.month
              ? AreaChart(values: cumulative, totalSlots: series.length, labelFor: (i) => Fmt.date(DateTime(from.year, from.month, i + 1)))
              : BarChart(values: series, labels: labels, highlight: busiest < 0 ? null : busiest),
        ),
        if (categories.isNotEmpty) ...[
          SectionTitle(tr('categories')),
          KCard(
            key: ValueKey('cats$_period$_back'),
            child: Column(children: [
              DonutChart(slices: [for (final c in categories) Slice(c.key.name, c.value, c.key.tint)], centerLabel: tr('spending')),
              const SizedBox(height: 10),
              for (final c in categories)
                LegendRow(
                  Slice(c.key.name, c.value, c.key.tint),
                  categoryTotal,
                  trailing: !advanced || (previousByCategory[c.key.key] ?? 0) <= 0 ? null : '${c.value >= previousByCategory[c.key.key]! ? '▲' : '▼'}${((c.value - previousByCategory[c.key.key]!).abs() / previousByCategory[c.key.key]! * 100).round()}%',
                ),
            ]),
          ),
        ],
        if (advanced && total > 0) ...[
          SectionTitle(tr('payment_modes')),
          KCard(
            child: Column(children: [
              SplitBar(modes),
              const SizedBox(height: 10),
              for (final m in modes.where((m) => m.value > 0)) LegendRow(m, modes.fold(0.0, (a, b) => a + b.value)),
            ]),
          ),
        ],
        if (advanced && payers.length > 1) ...[
          SectionTitle(tr('paid_by')),
          KCard(
            child: Column(children: [
              for (final p in payers) LegendRow(Slice(p.key.name, p.value, context.cs.primary), payers.fold(0.0, (a, b) => a + b.value)),
            ]),
          ),
        ],
        if (!advanced) ...[
          const SizedBox(height: 16),
          KCard(
            child: Column(children: [
              Row(children: [
                const Sticker('lock', size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('insights_locked_title'), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                    Text(tr('insights_locked_body'), style: context.tt.bodySmall),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              KButton(
                tr('unlock_watch_video'),
                icon: Icons.play_circle_filled_rounded,
                onTap: () => showUnlockSheet(context, featureId: RewardCatalog.insights, featureName: tr('rw_insights')),
              ),
              const SizedBox(height: 8),
              KButton(tr('shop'), tonal: true, icon: Icons.storefront_rounded, onTap: () => open(context, const RewardsScreen(initialTab: 2))),
            ]),
          ),
        ],
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600)),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
      ]),
    );
  }
}
