import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'avatar_studio.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('family_members'),
      subtitle: trPlural('family_sub', app.members.length),
      bottom: KButton(tr('add_member'), icon: Icons.person_add_alt_1_rounded, onTap: () => _edit(context, null)),
      children: [
        Text(tr('family_intro'), style: context.tt.bodySmall),
        const SizedBox(height: 14),
        for (final m in app.members)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KCard(
              onTap: () => _edit(context, m),
              child: Row(children: [
                Pressable(onTap: () => open(context, AvatarStudioScreen(m)), child: AvatarView(m.avatar.copyWith(mood: Mood.happy), size: 68)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Pill(tr('rel_${m.relation}')),
                      Pill(m.hasPin ? tr('pin_set') : tr('no_pin'), color: m.hasPin ? good : context.cs.onSurfaceVariant, icon: Icon(m.hasPin ? Icons.lock_rounded : Icons.lock_open_rounded, size: 13, color: m.hasPin ? good : context.cs.onSurfaceVariant)),
                    ]),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: context.cs.onSurfaceVariant),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        Text(tr('family_local_only'), style: context.tt.bodySmall),
      ],
    );
  }

  Future<void> _edit(BuildContext context, Member? existing) async {
    final app = AppScope.read(context);
    final name = TextEditingController(text: existing?.name ?? '');
    var relation = existing?.relation ?? 'partner';
    var gender = existing?.avatar.gender ?? Gender.female;
    await showKSheet<void>(
      context,
      title: existing == null ? tr('add_member') : tr('edit_member'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: name, label: tr('name'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          if (existing == null || !existing.isOwner) ...[
            Text(tr('relation'), style: sheet.tt.labelMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final r in relations.skip(1)) KChip(tr('rel_$r'), selected: relation == r, onTap: () => setState(() => relation = r))]),
            const SizedBox(height: 16),
          ],
          Text(tr('gender'), style: sheet.tt.labelMedium),
          const SizedBox(height: 8),
          Segmented<Gender>(options: {for (final g in Gender.values) g: tr('gender_${g.name}')}, value: gender, onChanged: (g) => setState(() => gender = g)),
          if (existing == null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(tr('member_random_look'), style: sheet.tt.bodySmall)),
          const SizedBox(height: 18),
          KButton(tr('save'), onTap: name.text.trim().isEmpty
              ? null
              : () async {
                  final nav = Navigator.of(sheet);
                  if (existing != null) {
                    existing
                      ..name = name.text.trim()
                      ..relation = existing.isOwner ? existing.relation : relation
                      ..avatar = existing.avatar.copyWith(gender: gender);
                    nav.pop();
                    await app.updateMember(existing);
                    return;
                  }
                  var join = false, resplit = false;
                  if (app.groups.isNotEmpty) {
                    final choice = await _ask(sheet, tr('join_groups_q', [name.text.trim()]), tr('join_groups_body'), [tr('join_resplit'), tr('join_from_now'), tr('join_not_now')]);
                    if (choice == null) return;
                    join = choice < 2;
                    resplit = choice == 0;
                  }
                  nav.pop();
                  await app.addMember(name: name.text, relation: relation, gender: gender, joinGroups: join, resplit: resplit);
                }),
          if (existing != null && !existing.isOwner) ...[
            const SizedBox(height: 8),
            KButton(tr('remove'), tonal: true, danger: true, onTap: () async {
              final nav = Navigator.of(sheet);
              final choice = await _ask(sheet, tr('remove_member_q', [existing.name]), tr('remove_member_body'), [tr('remove_resplit'), tr('remove_keep')]);
              if (choice == null) return;
              nav.pop();
              await app.removeMember(existing, resplit: choice == 0);
            }),
          ],
        ]),
      ),
    );
  }

  Future<int?> _ask(BuildContext context, String title, String body, List<String> options) {
    return showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title, style: d.tt.titleLarge),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(body),
          const SizedBox(height: 14),
          for (final (i, option) in options.indexed) Padding(padding: const EdgeInsets.only(top: 8), child: KButton(option, tonal: i > 0, onTap: () => Navigator.of(d).pop(i))),
          const SizedBox(height: 8),
          KButton(tr('cancel'), tonal: true, onTap: () => Navigator.of(d).pop()),
        ]),
      ),
    );
  }
}
