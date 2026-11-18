import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'common.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('tab_groups'),
      actions: [RoundIcon(Icons.add_rounded, filled: true, onTap: () => _create(context))],
      children: [
        if (app.groups.isEmpty) ...[
          EmptyState(emoji: '🤝', title: tr('no_groups_title'), body: tr('no_groups_body')),
          KButton(tr('new_group'), icon: Icons.add_rounded, onTap: () => _create(context)),
        ],
        for (final g in app.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Builder(builder: (_) {
              final mine = app.balances(g).where((b) => b.memberId == app.settings.activeMemberId).firstOrNull?.net ?? 0;
              return Pressable(
                scale: 0.98,
                onTap: () => open(context, GroupDetailScreen(g)),
                onLongPress: () async {
                  if (await confirm(context, title: tr('delete_group_q', [g.name]), body: tr('delete_group_body'), action: tr('delete'))) await app.deleteGroup(g);
                },
                child: KCard(
                  child: Row(children: [
                    IconTile(null, emoji: g.emoji, size: 54, color: const Color(0xFF7C4DFF)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                        Text(tr('members_hold_delete', [g.memberIds.length]), style: context.tt.bodySmall),
                        const SizedBox(height: 8),
                        _Faces([for (final id in g.memberIds) app.member(id)].whereType<Member>().toList()),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(mine.abs() < 0.005 ? tr('settled') : mine > 0 ? tr('owed_to_you') : tr('you_owe'), style: context.tt.labelSmall),
                      Text(mine.abs() < 0.005 ? '✓' : Fmt.money(mine.abs()), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: mine.abs() < 0.005 ? good : mine > 0 ? good : bad)),
                    ]),
                  ]),
                ),
              );
            }),
          ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController();
    const emojis = ['🏠', '✈️', '🎉', '🍕', '🏖️', '🛒', '🚗', '🎓'];
    var emoji = emojis.first;
    final picked = app.members.map((m) => m.id).toSet();
    await showKSheet<void>(
      context,
      title: tr('new_group'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: name, label: tr('group_name'), hint: tr('group_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            for (final e in emojis)
              Pressable(
                scale: 0.8,
                onTap: () => setState(() => emoji = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: emoji == e ? sheet.cs.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: emoji == e ? sheet.cs.primary : Colors.transparent, width: 2)),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text(tr('group_members'), style: sheet.tt.labelMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in app.members) MemberChip(m, selected: picked.contains(m.id), onTap: () => setState(() => picked.contains(m.id) ? picked.remove(m.id) : picked.add(m.id))),
          ]),
          const SizedBox(height: 18),
          KButton(tr('create_group'), onTap: name.text.trim().isNotEmpty && picked.length >= 2
              ? () async {
                  final nav = Navigator.of(sheet);
                  await app.saveGroup(Group(name: name.text, emoji: emoji, memberIds: picked.toList()));
                  nav.pop();
                }
              : null),
        ]),
      ),
    );
  }
}

class _Faces extends StatelessWidget {
  const _Faces(this.members);
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: 28.0 + 20 * (min(members.length, 6) - 1),
      child: Stack(children: [
        for (var i = 0; i < min(members.length, 6); i++) Positioned(left: i * 20.0, child: AvatarView(members[i].avatar, size: 28)),
      ]),
    );
  }
}

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen(this.group, {super.key});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final balances = app.balances(group);
    final plan = SplitCalculator.settlements(balances);
    final shared = app.groupExpenses(group);
    final top = balances.fold(0.0, (m, b) => max(m, b.net.abs()));
    return KPage(
      title: '${group.emoji} ${group.name}',
      actions: [RoundIcon(Icons.ios_share_rounded, onTap: () => Share.share(app.groupSummary(group)))],
      bottom: KButton(tr('add_shared_expense'), icon: Icons.add_rounded, onTap: () => open(context, AddExpenseScreen(groupId: group.id), rise: true)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('total_shared'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            CountUp(max(AppState.net(shared), 0.0), style: context.tt.displaySmall!.copyWith(color: Colors.white)),
          ]),
        ),
        SectionTitle(tr('balances')),
        KCard(
          child: Column(children: [
            for (final b in balances)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  if (app.member(b.memberId) != null) AvatarView(app.member(b.memberId)!.avatar, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(b.name, style: context.tt.titleSmall)),
                        Text(b.net.abs() < 0.005 ? tr('settled') : b.net > 0 ? tr('gets_amount', [Fmt.money(b.net)]) : tr('owes_amount', [Fmt.money(-b.net)]),
                            style: context.tt.labelMedium!.copyWith(color: b.net.abs() < 0.005 ? context.cs.onSurfaceVariant : b.net > 0 ? good : bad)),
                      ]),
                      const SizedBox(height: 6),
                      KProgress(top <= 0 ? 0.0 : b.net.abs() / top, color: b.net >= 0 ? good : bad, height: 7),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        if (plan.isNotEmpty) ...[
          SectionTitle(tr('settle_up')),
          for (final t in plan)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${t.fromName} → ${t.toName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                      Text(Fmt.money(t.amount), style: context.tt.titleLarge),
                    ]),
                  ),
                  KButton(tr('mark_paid'), expand: false, tonal: true, icon: Icons.check_rounded, onTap: () => app.settle(group, t)),
                ]),
              ),
            ),
        ],
        SectionTitle(tr('shared_expenses')),
        if (shared.isEmpty) EmptyState(emoji: '🧾', title: tr('nothing_shared_title'), body: tr('nothing_shared_body')),
        if (shared.isNotEmpty) KCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [for (final e in shared) ExpenseTile(e)])),
      ],
    );
  }
}
