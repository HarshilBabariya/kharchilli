import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'categories.dart';
import 'common.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = Days.today();
    final query = _search.text.trim().toLowerCase();
    final list = app.expenses.where((e) => (_category == null || e.category == _category) && (query.isEmpty || e.title.toLowerCase().contains(query) || e.note.toLowerCase().contains(query))).toList()
      ..sort((a, b) => b.day != a.day ? b.day.compareTo(a.day) : b.createdAt.compareTo(a.createdAt));
    final days = <int, List<Expense>>{};
    for (final e in list) {
      days.putIfAbsent(e.day, () => []).add(e);
    }
    final spent = app.spentIn(today), previous = app.spentIn(Days.addMonths(today, -1));
    return KPage(
      title: tr('tab_expenses'),
      subtitle: tr('n_expenses', [list.length]),
      actions: [
        RoundIcon(Icons.calendar_month_rounded, onTap: () => open(context, const CalendarScreen())),
        RoundIcon(Icons.tune_rounded, onTap: () => open(context, const CategoriesScreen())),
      ],
      children: [
        Row(children: [
          Expanded(child: _Tile(tr('this_month'), Fmt.money(spent), context.cs.primary)),
          const SizedBox(width: 12),
          Expanded(child: _Tile(tr('vs_last_month'), previous <= 0 ? '—' : '${spent <= previous ? '▼' : '▲'} ${((spent - previous).abs() / previous * 100).round()}%', spent <= previous ? good : bad)),
        ]),
        const SizedBox(height: 14),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: '${tr('search')} · ${tr('search_hint')}', prefixIcon: const Icon(Icons.search_rounded))),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: KChip(tr('all'), selected: _category == null, onTap: () => setState(() => _category = null))),
            for (final c in app.sortedCategories)
              Padding(padding: const EdgeInsets.only(right: 8), child: KChip(c.name, icon: c.icon, color: c.tint, selected: _category == c.key, onTap: () => setState(() => _category = c.key))),
          ]),
        ),
        if (list.isEmpty) EmptyState(emoji: '🧾', title: tr('no_expenses_title'), body: tr('no_expenses_body')),
        for (final day in days.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Row(children: [
              Expanded(child: Text(Fmt.relativeDay(Days.fromKey(day.key)), style: context.tt.labelMedium)),
              Text(Fmt.ledger(AppState.net(day.value)), style: context.tt.labelMedium),
            ]),
          ),
          KCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [for (final e in day.value) ExpenseTile(e)])),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.colour);
  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: context.tt.labelSmall),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: context.tt.titleLarge!.copyWith(color: colour))),
      ]),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = Days.monthStart(Days.today());
  DateTime? _picked = Days.today();

  void _shift(int by) {
    final next = Days.addMonths(_month, by);
    if (next.isAfter(Days.today())) return;
    setState(() {
      _month = next;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final today = Days.today();
    final budget = app.settings.monthlyBudget;
    final daily = budget > 0 ? budget / Days.inMonth(_month) : 0.0;
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final lead = (_month.weekday % 7 - firstWeekday + 7) % 7;
    final cells = lead + Days.inMonth(_month);
    final picked = _picked == null ? <Expense>[] : app.onDay(_picked!);
    return KPage(
      title: tr('calendar'),
      children: [
        KCard(
          child: Column(children: [
            Row(children: [
              RoundIcon(Icons.chevron_left_rounded, onTap: () => _shift(-1)),
              Expanded(child: Text(Fmt.monthYear(_month), textAlign: TextAlign.center, style: context.tt.titleLarge)),
              RoundIcon(Icons.chevron_right_rounded, onTap: () => _shift(1)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < 7; i++) Expanded(child: Text(Fmt.date(DateTime(2024, 1, 7 + firstWeekday + i), 'E').substring(0, 1), textAlign: TextAlign.center, style: context.tt.labelSmall)),
            ]),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.82,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < cells; i++)
                  if (i < lead)
                    const SizedBox()
                  else
                    Builder(builder: (_) {
                      final d = DateTime(_month.year, _month.month, i - lead + 1);
                      final future = d.isAfter(today);
                      final total = AppState.net(app.onDay(d));
                      final has = app.onDay(d).isNotEmpty;
                      final over = daily > 0 && total > daily;
                      final tint = !has || daily <= 0 ? cs.surfaceContainerHighest : (over ? bad : good).withValues(alpha: 0.18);
                      final on = _picked == d;
                      return Pressable(
                        scale: 0.88,
                        onTap: future ? null : () => setState(() => _picked = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(color: on ? cs.primary : tint, borderRadius: BorderRadius.circular(12), border: d == today && !on ? Border.all(color: cs.primary, width: 1.6) : null),
                          child: Opacity(
                            opacity: future ? 0.35 : 1,
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('${d.day}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: on ? Colors.white : cs.onSurface)),
                              if (has) FittedBox(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(Fmt.compact(total), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: on ? Colors.white : total < 0 ? good : over ? bad : cs.onSurfaceVariant)))),
                            ]),
                          ),
                        ),
                      );
                    }),
              ],
            ),
            const SizedBox(height: 12),
            Text(budget > 0 ? tr('avg_daily_budget', [Fmt.money(daily)]) : tr('calendar_no_budget'), textAlign: TextAlign.center, style: context.tt.bodySmall),
            if (budget > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Pill(tr('within_budget'), color: good), const SizedBox(width: 8), Pill(tr('over_budget'), color: bad)]),
              ),
          ]),
        ),
        if (_picked != null) ...[
          SectionTitle('${Fmt.relativeDay(_picked!)} · ${Fmt.ledger(AppState.net(picked))}'),
          if (picked.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(tr('calendar_quiet_day'), style: context.tt.bodyMedium)),
          if (picked.isNotEmpty) KCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [for (final e in picked) ExpenseTile(e)])),
        ],
      ],
    );
  }
}
