import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'cards.dart';
import 'common.dart';
import 'export.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('tab_groups'),
      actions: [RoundIcon(Icons.add_rounded, filled: true, onTap: () => editGroup(context))],
      children: [
        if (app.groups.isEmpty) ...[
          EmptyState(art: 'friends', title: tr('no_groups_title'), body: tr('no_groups_body')),
          KButton(tr('new_group'), icon: Icons.add_rounded, onTap: () => editGroup(context)),
        ],
        if (app.myDues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: KCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('across_groups'), style: context.tt.titleLarge),
                const SizedBox(height: 6),
                for (final d in app.myDues.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      AvatarView(d.key.avatar, size: 36),
                      const SizedBox(width: 12),
                      Expanded(child: Text(d.value > 0 ? tr('owes_you', [d.key.name]) : tr('you_owe_name', [d.key.name]), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall)),
                      Text(Fmt.money(d.value.abs()), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: d.value > 0 ? good : bad)),
                    ]),
                  ),
              ]),
            ),
          ),
        for (final g in app.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Builder(builder: (_) {
              final mine = app.balances(g).where((b) => b.memberId == app.settings.activeMemberId).firstOrNull?.net ?? 0;
              return Pressable(
                scale: 0.98,
                onTap: () => open(context, GroupDetailScreen(g)),
                child: KCard(
                  child: Row(children: [
                    groupSticker(g.icon, size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                        Text(tr('n_members', [g.memberIds.length]), style: context.tt.bodySmall),
                        const SizedBox(height: 8),
                        _Faces([for (final id in g.memberIds) app.member(id)].whereType<Member>().toList()),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(mine.abs() < 0.005 ? tr('settled') : mine > 0 ? tr('owed_to_you') : tr('you_owe'), style: context.tt.labelSmall),
                      const SizedBox(height: 2),
                      if (mine.abs() < 0.005) const Icon(Icons.check_circle_rounded, color: good, size: 24) else Text(Fmt.money(mine.abs()), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: mine > 0 ? good : bad)),
                    ]),
                  ]),
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// The sheet that creates a group, or edits [existing].
Future<void> editGroup(BuildContext context, [Group? existing]) async {
  final app = AppScope.read(context);
  final name = TextEditingController(text: existing?.name ?? '');
  var icon = existing?.icon ?? groupIcons.first;
  final picked = (existing?.memberIds ?? app.members.map((m) => m.id)).toSet();
  await showKSheet<void>(
    context,
    title: existing == null ? tr('new_group') : tr('edit_group'),
    pinned: true,
    builder: (sheet) => StatefulBuilder(
      builder: (_, setState) {
        final taken = app.groups.any((g) => g != existing && g.name.toLowerCase() == name.text.trim().toLowerCase());
        return KSheetForm(body: [
          KField(controller: name, label: tr('group_name'), hint: tr('group_name_hint'), error: taken ? tr('name_taken') : null, onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final key in groupIcons)
              Pressable(
                scale: 0.85,
                onTap: () => setState(() => icon = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: icon == key ? sheet.cs.primary : Colors.transparent, width: 2.5)),
                  child: AnimatedOpacity(duration: const Duration(milliseconds: 180), opacity: icon == key ? 1 : 0.55, child: groupSticker(key, size: 46)),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text(tr('group_members'), style: sheet.tt.labelMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in app.members) MemberChip(m, selected: picked.contains(m.id), onTap: () => setState(() => picked.contains(m.id) ? picked.remove(m.id) : picked.add(m.id))),
          ]),
          if (existing != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(tr('edit_group_hint'), style: sheet.tt.bodySmall)),
        ], actions: [
          KButton(existing == null ? tr('create_group') : tr('save_changes'), onTap: name.text.trim().isNotEmpty && !taken && picked.length >= 2
              ? () async {
                  Navigator.of(sheet).pop();
                  final group = existing ?? Group(name: '', memberIds: []);
                  group
                    ..name = name.text
                    ..icon = icon
                    ..memberIds = picked.toList();
                  await app.saveGroup(group);
                }
              : null),
        ]);
      },
    ),
  );
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
      title: group.name,
      actions: [
        RoundIcon(Icons.edit_rounded, onTap: () => editGroup(context, group)),
        RoundIcon(Icons.ios_share_rounded, onTap: () => shareCard(context, GroupCard(group), file: 'gharcha-group', text: app.groupSummary(group))),
        RoundIcon(Icons.delete_outline_rounded, onTap: () async {
          final nav = Navigator.of(context);
          if (await confirm(context, title: tr('delete_group_q', [group.name]), body: tr('delete_group_body'), action: tr('delete'))) {
            nav.pop();
            await app.deleteGroup(group);
          }
        }),
      ],
      bottom: KButton(tr('add_shared_expense'), icon: Icons.add_rounded, onTap: () => open(context, AddExpenseScreen(groupId: group.id), rise: true)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              groupSticker(group.icon, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(tr('total_shared'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CountUp(max(AppState.net(shared), 0.0), style: context.tt.displaySmall!.copyWith(color: Colors.white))),
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
              child: _SettleCard(group, t),
            ),
        ],
        SectionTitle(tr('shared_expenses')),
        if (shared.isEmpty) EmptyState(art: 'receipt', title: tr('nothing_shared_title'), body: tr('nothing_shared_body')),
        if (shared.isNotEmpty) KCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [for (final e in shared) ExpenseTile(e)])),
      ],
    );
  }
}

/// One payment of the settle-up plan, with the ways to get it done.
class _SettleCard extends StatelessWidget {
  const _SettleCard(this.group, this.transfer);
  final Group group;
  final Transfer transfer;

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = transfer;
    final me = app.settings.activeMemberId;
    final payeeUpi = app.member(t.toId)?.upiId ?? '';
    final canPay = t.fromId == me && app.settings.currencyCode == 'INR';
    return KCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Row(children: [
              Flexible(child: Text(t.fromName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 16, color: context.cs.onSurfaceVariant)),
              Flexible(child: Text(t.toName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(Fmt.money(t.amount), style: context.tt.titleLarge),
        ]),
        if (canPay && payeeUpi.isEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('upi_missing', [t.toName]), style: context.tt.bodySmall)),
        const SizedBox(height: 12),
        Row(children: [
          if (canPay && payeeUpi.isNotEmpty) ...[
            Expanded(
              child: KButton(tr('pay_upi_now'), icon: Icons.qr_code_rounded, onTap: () async {
                final paid = await _launch(Uri(scheme: 'upi', host: 'pay', queryParameters: {'pa': payeeUpi, 'pn': t.toName, 'am': t.amount.toStringAsFixed(2), 'cu': 'INR', 'tn': group.name}));
                if (!paid && context.mounted) toast(context, tr('upi_no_app'));
              }),
            ),
            const SizedBox(width: 10),
          ],
          if (t.toId == me) ...[
            Expanded(
              child: KButton(tr('remind'), tonal: true, icon: Icons.send_rounded, onTap: () => shareCard(context, ReminderCard(group, t), file: 'gharcha-reminder', text: tr('remind_message', [t.fromName, Fmt.money(t.amount), group.name]))),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: KButton(tr('mark_paid'), tonal: true, icon: Icons.check_rounded, onTap: () => app.settle(group, t))),
        ]),
      ]),
    );
  }
}
