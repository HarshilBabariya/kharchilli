import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/parsers.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'common.dart';

Future<DateTime?> _pickDay(BuildContext context, {DateTime? initial}) {
  final today = Days.today();
  return showDatePicker(context: context, initialDate: initial ?? today, firstDate: DateTime(today.year - 1), lastDate: DateTime(today.year + 15));
}

/// A date row for the sheets below: shows the chosen day, opens the picker, and can be cleared when optional.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.label, required this.day, required this.onPicked, this.onCleared});
  final String label;
  final DateTime? day;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    return NavRow(
      icon: Icons.event_rounded,
      title: label,
      subtitle: day == null ? tr('not_set') : Fmt.date(day!, 'd MMM yyyy'),
      trailing: day != null && onCleared != null ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: onCleared) : null,
      onTap: () async {
        final picked = await _pickDay(context, initial: day);
        if (picked != null) onPicked(picked);
      },
    );
  }
}

/// A grocery list anyone in the house can add to; ticked items become one expense.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _entry = TextEditingController();

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _add(AppState app) {
    final name = _entry.text.trim();
    if (name.isEmpty) return;
    _entry.clear();
    app.put(app.shopping, ShopItem(name: name.capitalised));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final done = app.shopping.where((i) => i.done).toList();
    Widget row(ShopItem item) => Pressable(
          onTap: () {
            item.done = !item.done;
            app.put(app.shopping, item);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(children: [
              Icon(item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: item.done ? good : context.cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(item.name, style: context.tt.titleMedium!.copyWith(decoration: item.done ? TextDecoration.lineThrough : null, color: item.done ? context.cs.onSurfaceVariant : null))),
              IconButton(visualDensity: VisualDensity.compact, icon: Icon(Icons.close_rounded, size: 20, color: context.cs.onSurfaceVariant), onPressed: () => app.drop(app.shopping, item)),
            ]),
          ),
        );
    return KPage(
      title: tr('shopping_list'),
      subtitle: tr('shopping_count', [app.shopping.length - done.length]),
      bottom: done.isEmpty
          ? null
          : KButton(tr('shopping_log', [done.length]), icon: Icons.receipt_long_rounded, onTap: () {
              final bought = [...done];
              open(
                context,
                AddExpenseScreen(
                  draft: VoiceResult(null, app.category(BuiltInCategories.groceries).name, BuiltInCategories.groceries, null, bought.map((i) => i.name).join(', '), false),
                  onSaved: () {
                    for (final item in bought) {
                      app.drop(app.shopping, item);
                    }
                  },
                ),
                rise: true,
              );
            }),
      children: [
        Row(children: [
          Expanded(child: TextField(controller: _entry, textCapitalization: TextCapitalization.sentences, onSubmitted: (_) => _add(app), decoration: InputDecoration(hintText: tr('shopping_hint'), prefixIcon: const Icon(Icons.add_shopping_cart_rounded)))),
          const SizedBox(width: 10),
          RoundIcon(Icons.add_rounded, filled: true, onTap: () => _add(app)),
        ]),
        const SizedBox(height: 14),
        if (app.shopping.isEmpty)
          EmptyState(art: 'group_shop', title: tr('shopping_empty_title'), body: tr('shopping_empty_body'))
        else
          KCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [for (final item in app.shopping.where((i) => !i.done)) row(item), for (final item in done) row(item)]),
          ),
      ],
    );
  }
}

/// Money lent to and borrowed from people, outside group splits.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final app = AppScope.read(context);
    final person = TextEditingController(), amount = TextEditingController();
    var lent = true;
    DateTime? due;
    await showKSheet<void>(
      context,
      title: tr('loan_new'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Segmented<bool>(options: {true: tr('loan_lent'), false: tr('loan_borrowed')}, value: lent, color: lent ? good : bad, onChanged: (v) => setState(() => lent = v)),
          const SizedBox(height: 14),
          KField(controller: person, label: tr('loan_person'), hint: tr('loan_person_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          KField(controller: amount, label: tr('amount'), number: true, onChanged: (_) => setState(() {})),
          _DayRow(label: tr('loan_due'), day: due, onPicked: (d) => setState(() => due = d), onCleared: () => setState(() => due = null)),
          const SizedBox(height: 10),
          KButton(tr('save'), onTap: person.text.trim().isEmpty || (double.tryParse(amount.text) ?? 0) <= 0
              ? null
              : () {
                  Navigator.of(sheet).pop();
                  final value = double.parse(amount.text);
                  app.put(app.loans, Loan(person: person.text.trim().capitalised, amount: lent ? value : -value, day: Days.key(Days.today()), dueDay: due == null ? null : Days.key(due!)));
                }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = Days.today();
    final pending = app.loans.where((l) => !l.settled).toList()..sort((a, b) => (a.dueDay ?? 99999999).compareTo(b.dueDay ?? 99999999));
    final closed = app.loans.where((l) => l.settled).toList();
    final toGet = pending.where((l) => l.amount > 0).fold(0.0, (s, l) => s + l.amount), toPay = pending.where((l) => l.amount < 0).fold(0.0, (s, l) => s - l.amount);

    Widget card(Loan l) {
      final lent = l.amount > 0;
      final left = l.dueDay == null ? null : Days.between(today, Days.fromKey(l.dueDay!));
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: KCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Column(children: [
            Row(children: [
              IconTile(lent ? Icons.north_east_rounded : Icons.south_west_rounded, color: l.settled ? context.cs.onSurfaceVariant : lent ? good : bad),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.person, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                  Text(
                    [lent ? tr('loan_lent') : tr('loan_borrowed'), Fmt.date(Days.fromKey(l.day), 'd MMM'), if (!l.settled && left != null) left < 0 ? tr('overdue_days', [-left]) : tr('loan_due_in', [left])].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodySmall!.copyWith(color: !l.settled && left != null && left < 0 ? bad : null),
                  ),
                ]),
              ),
              Text(Fmt.money(l.amount.abs()), style: context.tt.titleLarge!.copyWith(decoration: l.settled ? TextDecoration.lineThrough : null)),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: context.cs.onSurfaceVariant),
                onPressed: () {
                  toast(context, tr('deleted_msg', [l.person]), onUndo: () => app.put(app.loans, l));
                  app.drop(app.loans, l);
                },
              ),
            ]),
            if (!l.settled)
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Row(children: [
                  if (lent) ...[
                    Expanded(child: KButton(tr('remind'), tonal: true, icon: Icons.send_rounded, onTap: () => Share.share(tr('loan_remind_message', [l.person, Fmt.money(l.amount)])))),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: KButton(tr('settled'), tonal: !lent, icon: Icons.check_rounded, onTap: () {
                      l.settled = true;
                      app.put(app.loans, l);
                    }),
                  ),
                ]),
              ),
          ]),
        ),
      );
    }

    return KPage(
      title: tr('loans'),
      bottom: KButton(tr('loan_new'), icon: Icons.add_rounded, onTap: () => _add(context)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Row(children: [
            for (final (label, value) in [(tr('loan_to_get'), toGet), (tr('loan_to_pay'), toPay)])
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(Fmt.money(value), style: context.tt.headlineSmall!.copyWith(color: Colors.white))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        if (app.loans.isEmpty) EmptyState(art: 'friends', title: tr('loans_empty_title'), body: tr('loans_empty_body')),
        for (final l in pending) card(l),
        if (closed.isNotEmpty) ...[SectionTitle(tr('settled')), for (final l in closed) card(l)],
      ],
    );
  }
}

/// Things being saved up for, with how far along each is.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController(), target = TextEditingController();
    DateTime? due;
    await showKSheet<void>(
      context,
      title: tr('goal_new'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: name, label: tr('goal_name'), hint: tr('goal_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          KField(controller: target, label: tr('goal_target'), number: true, onChanged: (_) => setState(() {})),
          _DayRow(label: tr('goal_by'), day: due, onPicked: (d) => setState(() => due = d), onCleared: () => setState(() => due = null)),
          const SizedBox(height: 10),
          KButton(tr('save'), onTap: name.text.trim().isEmpty || (double.tryParse(target.text) ?? 0) <= 0
              ? null
              : () {
                  Navigator.of(sheet).pop();
                  app.put(app.goals, Goal(name: name.text.trim().capitalised, target: double.parse(target.text), dueMonth: due == null ? null : Days.monthKey(due!)));
                }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = Days.today();
    return KPage(
      title: tr('goals'),
      bottom: KButton(tr('goal_new'), icon: Icons.add_rounded, onTap: () => _add(context)),
      children: [
        if (app.goals.isEmpty) EmptyState(art: 'gold', title: tr('goals_empty_title'), body: tr('goals_empty_body')),
        for (final g in app.goals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline_rounded, color: context.cs.onSurfaceVariant),
                    onPressed: () {
                      toast(context, tr('deleted_msg', [g.name]), onUndo: () => app.put(app.goals, g));
                      app.drop(app.goals, g);
                    },
                  ),
                ]),
                Text(tr('goal_progress', [Fmt.money(g.saved), Fmt.money(g.target)]), style: context.tt.bodyMedium),
                const SizedBox(height: 10),
                KProgress(g.target <= 0 ? 0 : g.saved / g.target, color: g.left <= 0 ? good : context.cs.primary, height: 10),
                const SizedBox(height: 8),
                Text(
                  g.left <= 0 ? tr('goal_reached') : g.monthly(today) == null ? tr('goal_left', [Fmt.money(g.left)]) : tr('goal_monthly', [Fmt.money(g.monthly(today)!), Fmt.money(g.left)]),
                  style: context.tt.bodySmall!.copyWith(color: g.left <= 0 ? good : null, fontWeight: g.left <= 0 ? FontWeight.w700 : null),
                ),
                const SizedBox(height: 12),
                KButton(tr('goal_add_money'), tonal: true, icon: Icons.savings_rounded, onTap: () async {
                  final amount = await askAmount(context, title: tr('goal_add_money'));
                  if (amount == null || amount <= 0) return;
                  g.saved += amount;
                  await app.put(app.goals, g);
                }),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Warranties, policies and other papers, soonest to run out first.
class PapersScreen extends StatelessWidget {
  const PapersScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController();
    DateTime? expiry;
    var photo = '';
    await showKSheet<void>(
      context,
      title: tr('paper_new'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: name, label: tr('paper_name'), hint: tr('paper_name_hint'), onChanged: (_) => setState(() {})),
          _DayRow(label: tr('paper_expiry'), day: expiry, onPicked: (d) => setState(() => expiry = d)),
          NavRow(
            icon: Icons.photo_camera_rounded,
            title: tr('paper_photo'),
            subtitle: photo.isEmpty ? tr('receipt_photo_add') : tr('receipt_photo_added'),
            onTap: () async {
              final picked = await pickPhoto(sheet, title: tr('paper_photo'), current: photo);
              if (picked != null) setState(() => photo = picked);
            },
          ),
          const SizedBox(height: 10),
          KButton(tr('save'), onTap: name.text.trim().isEmpty || expiry == null
              ? null
              : () {
                  Navigator.of(sheet).pop();
                  app.put(app.papers, Paper(name: name.text.trim().capitalised, expiryDay: Days.key(expiry!), photo: photo));
                }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = Days.today();
    final sorted = [...app.papers]..sort((a, b) => a.expiryDay.compareTo(b.expiryDay));
    return KPage(
      title: tr('papers'),
      bottom: KButton(tr('paper_new'), icon: Icons.add_rounded, onTap: () => _add(context)),
      children: [
        if (sorted.isEmpty) EmptyState(art: 'lock', title: tr('papers_empty_title'), body: tr('papers_empty_body')),
        for (final p in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              onTap: p.photo.isEmpty ? null : () => showKSheet<void>(context, title: p.name, builder: (_) => ClipRRect(borderRadius: BorderRadius.circular(18), child: InteractiveViewer(child: Image.file(File('${app.photosDir}/${p.photo}'), fit: BoxFit.contain)))),
              child: Builder(builder: (context) {
                final left = Days.between(today, Days.fromKey(p.expiryDay));
                final tone = left < 0 ? bad : left <= 30 ? warn : good;
                return Row(children: [
                  if (p.photo.isEmpty) IconTile(Icons.description_rounded, color: tone) else ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File('${app.photosDir}/${p.photo}'), width: 44, height: 44, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                      Text(Fmt.date(Days.fromKey(p.expiryDay), 'd MMM yyyy'), style: context.tt.bodySmall),
                    ]),
                  ),
                  Pill(left < 0 ? tr('expired') : tr('days_left', [left]), color: tone),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: context.cs.onSurfaceVariant),
                    onPressed: () {
                      toast(context, tr('deleted_msg', [p.name]), onUndo: () => app.put(app.papers, p));
                      app.drop(app.papers, p);
                    },
                  ),
                ]);
              }),
            ),
          ),
      ],
    );
  }
}

/// Cash, bank accounts and wallets, each with what should be in it.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _edit(BuildContext context, Account? existing) async {
    final app = AppScope.read(context);
    final name = TextEditingController(text: existing?.name ?? ''), opening = TextEditingController(text: existing == null ? '' : Fmt.number(existing.opening).replaceAll(',', ''));
    await showKSheet<void>(
      context,
      title: existing == null ? tr('account_new') : existing.name,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: name, label: tr('account_name'), hint: tr('account_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          KField(controller: opening, label: tr('account_opening'), number: true),
          const SizedBox(height: 14),
          KButton(tr('save'), onTap: name.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(sheet).pop();
                  final account = existing ?? Account(name: '');
                  account
                    ..name = name.text.trim().capitalised
                    ..opening = double.tryParse(opening.text) ?? 0;
                  app.put(app.accounts, account);
                }),
          if (existing != null) ...[
            const SizedBox(height: 8),
            KButton(tr('delete'), tonal: true, danger: true, onTap: () {
              Navigator.of(sheet).pop();
              toast(context, tr('deleted_msg', [existing.name]), onUndo: () => app.put(app.accounts, existing));
              app.drop(app.accounts, existing);
            }),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('accounts'),
      bottom: KButton(tr('account_new'), icon: Icons.add_rounded, onTap: () => _edit(context, null)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('accounts_total'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            FittedBox(fit: BoxFit.scaleDown, child: Text(Fmt.money(app.accounts.fold(0.0, (sum, a) => sum + app.balanceOf(a))), style: context.tt.displaySmall!.copyWith(color: Colors.white))),
            const SizedBox(height: 4),
            Text(tr('accounts_hint'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
          ]),
        ),
        const SizedBox(height: 14),
        for (final a in app.accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KCard(
              padding: const EdgeInsets.all(14),
              onTap: () => _edit(context, a),
              child: Row(children: [
                const IconTile(Icons.account_balance_wallet_rounded, color: Color(0xFF039BE5)),
                const SizedBox(width: 12),
                Expanded(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium)),
                Text(Fmt.money(app.balanceOf(a)), style: context.tt.titleLarge!.copyWith(color: app.balanceOf(a) < 0 ? bad : null)),
              ]),
            ),
          ),
      ],
    );
  }
}
