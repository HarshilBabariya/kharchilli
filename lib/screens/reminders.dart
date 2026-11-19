import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  String _when(DateTime at) {
    final now = DateTime.now();
    final days = Days.between(now, at);
    final time = Fmt.time(at.hour, at.minute);
    if (at.difference(now).inMinutes < 60) return tr('rem_in_minutes', [at.difference(now).inMinutes + 1]);
    if (days == 0) return tr('rem_today_at', [time]);
    if (days == 1) return tr('rem_tomorrow_at', [time]);
    return '${Fmt.date(at, 'EEE, d MMM')} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final upcoming = app.upcomingReminders;
    final today = Days.today();
    final monthAhead = upcoming.where((u) => Days.between(today, u.value) <= 30);
    final billsAhead = monthAhead.fold(0.0, (sum, u) => sum + (u.key.amount ?? 0));
    final paused = app.reminders.where((r) => !r.enabled).toList();
    Iterable<MapEntry<Reminder, DateTime>> bucket(int from, int to) => upcoming.where((u) => Days.between(today, u.value) >= from && Days.between(today, u.value) <= to);
    final groups = {tr('rem_soon'): bucket(0, 1), tr('rem_this_week'): bucket(2, 7), tr('rem_later'): bucket(8, 100000)};
    return KPage(
      title: tr('reminders_bills'),
      subtitle: trPlural('rem_active', upcoming.length),
      bottom: KButton(tr('new_reminder'), icon: Icons.add_alarm_rounded, onTap: () => _edit(context, null)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('rem_next_up'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(upcoming.isEmpty ? tr('rem_all_quiet') : upcoming.first.key.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.headlineSmall!.copyWith(color: Colors.white)),
            if (upcoming.isNotEmpty) Text(_when(upcoming.first.value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            _Timeline([for (final u in monthAhead) Days.between(today, u.value)]),
            const SizedBox(height: 10),
            Text(tr('rem_bills_ahead', [Fmt.money(billsAhead), upcoming.length]), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
          ]),
        ),
        if (app.reminders.any((r) => r.enabled && r.isBill)) ...[
          const SizedBox(height: 14),
          _BillCalendar(app.reminders.where((r) => r.enabled && r.isBill).toList()),
        ],
        if (app.reminders.isEmpty) EmptyState(art: 'bell', title: tr('nothing_scheduled_title'), body: tr('nothing_scheduled_body')),
        for (final g in groups.entries)
          if (g.value.isNotEmpty) ...[
            SectionTitle(g.key),
            for (final u in g.value) _ReminderCard(u.key, _when(u.value), onTap: () => _edit(context, u.key)),
          ],
        if (paused.isNotEmpty) ...[
          SectionTitle(tr('paused')),
          for (final r in paused) _ReminderCard(r, r.schedule, onTap: () => _edit(context, r)),
        ],
      ],
    );
  }

  Future<void> _edit(BuildContext context, Reminder? existing) async {
    final app = AppScope.read(context);
    final r = existing ?? Reminder(title: '', hour: 9, minute: 0, dayOfMonth: DateTime.now().day, month: DateTime.now().month, weekday: DateTime.now().weekday);
    final title = TextEditingController(text: r.title);
    final amount = TextEditingController(text: r.amount == null ? '' : Fmt.number(r.amount!).replaceAll(',', ''));
    var repeat = r.repeat, hour = r.hour, minute = r.minute, dayOfMonth = r.dayOfMonth, weekday = r.weekday, month = r.month, autoLog = r.autoLog, enabled = r.enabled;
    var category = r.category;
    var onceDay = r.onceDay == null ? Days.today() : Days.fromKey(r.onceDay!);
    const presets = ['preset_rent', 'preset_emi', 'preset_electricity', 'preset_insurance', 'preset_school_fees', 'preset_daily_nudge'];
    await showKSheet<void>(
      context,
      title: existing == null ? tr('new_reminder') : tr('edit_reminder'),
      pinned: true,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) {
          final hasAmount = (double.tryParse(amount.text) ?? 0) > 0;
          return KSheetForm(body: [
            if (existing == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in presets)
                    KChip(tr(p), selected: title.text == tr(p), onTap: () => setState(() {
                          title.text = tr(p);
                          repeat = p == 'preset_daily_nudge' ? RepeatRule.daily : RepeatRule.monthly;
                        })),
                ]),
              ),
            KField(controller: title, label: tr('title'), hint: tr('reminder_title_hint'), onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            KField(controller: amount, label: tr('amount_optional'), number: true, onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            Text(tr('repeats'), style: sheet.tt.labelMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final rule in RepeatRule.values) KChip(tr(rule.labelKey), selected: repeat == rule, onTap: () => setState(() => repeat = rule))]),
            const SizedBox(height: 10),
            NavRow(
              icon: Icons.schedule_rounded,
              title: tr('time'),
              subtitle: Fmt.time(hour, minute),
              onTap: () async {
                final t = await showTimePicker(context: sheet, initialTime: TimeOfDay(hour: hour, minute: minute));
                if (t != null) {
                  setState(() {
                    hour = t.hour;
                    minute = t.minute;
                  });
                }
              },
            ),
            if (repeat == RepeatRule.once || repeat == RepeatRule.yearly)
              NavRow(
                icon: Icons.event_rounded,
                title: tr('date'),
                subtitle: Fmt.date(repeat == RepeatRule.once ? onceDay : DateTime(2024, month, dayOfMonth), repeat == RepeatRule.once ? 'd MMM yyyy' : 'd MMMM'),
                onTap: () async {
                  final d = await showDatePicker(context: sheet, initialDate: onceDay, firstDate: Days.today(), lastDate: DateTime(Days.today().year + 5));
                  if (d != null) {
                    setState(() {
                      onceDay = d;
                      dayOfMonth = d.day;
                      month = d.month;
                    });
                  }
                },
              ),
            if (repeat == RepeatRule.weekly)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  for (var d = 1; d <= 7; d++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Pressable(
                          onTap: () => setState(() => weekday = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: weekday == d ? sheet.cs.primary : sheet.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                            child: Text(Fmt.date(DateTime(2024, 1, d), 'E').substring(0, 1), style: TextStyle(fontWeight: FontWeight.w700, color: weekday == d ? Colors.white : sheet.cs.onSurface)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            if (repeat == RepeatRule.monthly)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${tr('day_of_month')} · $dayOfMonth', style: sheet.tt.labelMedium),
                  Slider(value: dayOfMonth.toDouble(), min: 1, max: 31, divisions: 30, onChanged: (v) => setState(() => dayOfMonth = v.round())),
                ]),
              ),
            NavRow(
              icon: category == null ? Icons.category_rounded : app.category(category!).icon,
              color: category == null ? null : app.category(category!).tint,
              title: tr('category_optional'),
              subtitle: category == null ? '—' : app.category(category!).name,
              onTap: () async {
                final picked = await pickCategory(sheet, selected: category);
                if (picked != null) setState(() => category = picked);
              },
            ),
            if (hasAmount) NavRow(icon: Icons.bolt_rounded, color: good, title: tr('auto_log'), subtitle: tr('auto_log_sub'), trailing: KSwitch(value: autoLog, onChanged: (v) => setState(() => autoLog = v))),
            if (existing != null) NavRow(icon: Icons.notifications_active_rounded, title: tr('active'), trailing: KSwitch(value: enabled, onChanged: (v) => setState(() => enabled = v))),
            ], actions: [
            KButton(tr('save_reminder'), onTap: title.text.trim().isEmpty
                ? null
                : () async {
                    final nav = Navigator.of(sheet);
                    r
                      ..title = title.text
                      ..amount = hasAmount ? double.parse(amount.text) : null
                      ..repeat = repeat
                      ..hour = hour
                      ..minute = minute
                      ..dayOfMonth = dayOfMonth
                      ..weekday = weekday
                      ..month = month
                      ..onceDay = repeat == RepeatRule.once ? Days.key(onceDay) : null
                      ..category = category
                      ..autoLog = hasAmount && autoLog
                      ..enabled = enabled;
                    if (r.autoLog && r.lastLoggedDay == 0) {
                      final today = Days.today();
                      final next = r.nextAfter(DateTime.now());
                      r.lastLoggedDay = Days.key(next != null && Days.of(next) == today ? DateTime(today.year, today.month, today.day - 1) : today);
                    }
                    nav.pop();
                    await app.saveReminder(r);
                  }),
            if (existing != null) ...[
              const SizedBox(height: 8),
              KButton(tr('delete'), tonal: true, danger: true, onTap: () async {
                final nav = Navigator.of(sheet);
                if (await confirm(sheet, title: tr('delete_reminder_q', [existing.title]), body: tr('delete_reminder_body'), action: tr('delete'))) {
                  nav.pop();
                  await app.deleteReminder(existing);
                }
              }),
            ],
          ]);
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard(this.reminder, this.when, {required this.onTap});
  final Reminder reminder;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: r.enabled ? 1 : 0.55,
          child: Row(children: [
            IconTile(r.isBill ? Icons.receipt_long_rounded : Icons.notifications_active_rounded, color: r.isBill ? const Color(0xFFFB8C00) : context.cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                Text('$when · ${tr(r.repeat.labelKey)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (r.isBill) Text(Fmt.money(r.amount!), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
              if (r.autoLog) Pill(tr('auto_badge'), color: good),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// The next 30 days as a strip; days with something due glow.
class _Timeline extends StatelessWidget {
  const _Timeline(this.dueInDays);
  final List<int> dueInDays;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var d = 0; d <= 30; d++)
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + d * 30),
            curve: Curves.easeOutBack,
            builder: (_, v, __) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              height: (dueInDays.contains(d) ? 26 : 10) * v,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: dueInDays.contains(d) ? 1 : 0.3), borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
    ]);
  }
}

/// This month as a grid with every bill's due day marked, what is still to pay, and what the recurring bills add up to.
class _BillCalendar extends StatelessWidget {
  const _BillCalendar(this.bills);
  final List<Reminder> bills;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final today = Days.today();
    final first = Days.monthStart(today);
    final end = DateTime(today.year, today.month + 1);
    final due = <int, double>{};
    for (final r in bills) {
      var from = first.subtract(const Duration(minutes: 1));
      for (var i = 0; i < 31; i++) {
        final next = r.nextAfter(from);
        if (next == null || !next.isBefore(end)) break;
        due[next.day] = (due[next.day] ?? 0) + r.amount!;
        from = next;
      }
    }
    final toPay = due.entries.where((d) => d.key >= today.day).fold(0.0, (sum, d) => sum + d.value);
    final monthly = bills.fold(0.0, (sum, r) => sum + r.amount! * switch (r.repeat) { RepeatRule.daily => 30, RepeatRule.weekly => 52 / 12, RepeatRule.monthly => 1, RepeatRule.yearly => 1 / 12, RepeatRule.once => 0 });
    return KCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(tr('bills_in', [Fmt.month(today)]), style: context.tt.titleLarge)),
          Text(tr('to_pay', [Fmt.money(toPay)]), style: context.tt.labelMedium!.copyWith(color: cs.primary)),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < first.weekday - 1; i++) const SizedBox(),
            for (var d = 1; d <= Days.inMonth(today); d++)
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !due.containsKey(d) ? null : d < today.day ? cs.surfaceContainerHighest : cs.primary,
                  border: d == today.day ? Border.all(color: cs.onSurface, width: 1.6) : null,
                ),
                child: Text('$d', style: TextStyle(fontSize: 12.5, fontWeight: due.containsKey(d) ? FontWeight.w800 : FontWeight.w500, color: due.containsKey(d) && d >= today.day ? Colors.white : cs.onSurfaceVariant)),
              ),
          ],
        ),
        if (monthly > 0) ...[
          const SizedBox(height: 12),
          Text(tr('recurring_cost', [Fmt.money(monthly), Fmt.money(monthly * 12)]), style: context.tt.bodySmall),
        ],
      ]),
    );
  }
}
