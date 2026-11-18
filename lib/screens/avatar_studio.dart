import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class AvatarStudioScreen extends StatefulWidget {
  const AvatarStudioScreen(this.member, {super.key});
  final Member member;

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  late AvatarConfig _look = widget.member.avatar;
  AvatarAction? _action = AvatarAction.wave;
  int _plays = 0;
  late final Timer _idle;

  @override
  void initState() {
    super.initState();
    _idle = Timer.periodic(const Duration(seconds: 11), (_) => _play(AvatarAction.values[Random().nextInt(AvatarAction.values.length)]));
  }

  @override
  void dispose() {
    _idle.cancel();
    super.dispose();
  }

  void _play(AvatarAction action) {
    if (mounted) {
      setState(() {
        _action = action;
        _plays++;
      });
    }
  }

  Future<void> _choose(RewardItem item, AvatarConfig next) async {
    final app = AppScope.read(context);
    if (!app.isUnlocked(item.id)) {
      final ok = await app.unlock(item);
      if (!mounted) return;
      if (!ok) {
        toast(context, item.pack != null ? tr('pack_only', [item.pack!.label]) : tr('need_more_points', [item.cost - app.settings.points, item.name]));
        return;
      }
      toast(context, tr('unlocked_msg', [item.emoji, item.name]));
    }
    setState(() => _look = next);
    _play(AvatarAction.spin);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    Widget title(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 10), child: Text(text, style: context.tt.labelMedium));
    Widget dots(List<int> colours, int selected, ValueChanged<int> pick) => Wrap(spacing: 12, children: [
          for (var i = 0; i < colours.length; i++)
            Pressable(
              scale: 0.8,
              onTap: () => pick(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Color(colours[i]), shape: BoxShape.circle, border: Border.all(color: selected == i ? cs.primary : cs.outlineVariant, width: selected == i ? 3.5 : 1)),
              ),
            ),
        ]);
    Widget items(RewardKind kind, String current, AvatarConfig Function(String id) apply) => SizedBox(
          height: 132,
          child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
            for (final item in RewardCatalog.ofKind(kind).where((i) => i.pack == null || i.pack == app.festival?.festival.pack || app.isUnlocked(i.id)))
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Pressable(
                  scale: 0.92,
                  onTap: () => _choose(item, apply(item.id)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: current == item.id ? cs.primary : cs.outlineVariant, width: current == item.id ? 2.5 : 1)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AvatarView(apply(item.id).copyWith(mood: Mood.happy), size: 58),
                      const SizedBox(height: 6),
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall!.copyWith(color: cs.onSurface)),
                      Text(app.isUnlocked(item.id) ? (current == item.id ? tr('wearing') : tr('owned')) : item.pack != null ? tr('claim_free') : tr('cost_tap', [item.cost]),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall!.copyWith(fontSize: 10, color: app.isUnlocked(item.id) ? good : cs.primary)),
                    ]),
                  ),
                ),
              ),
          ]),
        );

    return KPage(
      title: tr('avatar_studio'),
      subtitle: tr('avatar_of', [widget.member.name]),
      bottom: KButton(tr('save_look'), icon: Icons.check_rounded, onTap: () async {
        final nav = Navigator.of(context);
        widget.member.avatar = _look;
        await app.updateMember(widget.member);
        nav.pop();
      }),
      children: [
        Center(child: AvatarView(_look.copyWith(mood: _look.mood ?? app.mood), key: ValueKey(_plays), size: 190, animate: true, action: _action)),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
            for (final a in AvatarAction.values) Padding(padding: const EdgeInsets.only(right: 8), child: KChip('${a.emoji} ${a.label}', selected: false, onTap: () => _play(a))),
          ]),
        ),
        title(tr('gender')),
        Row(children: [for (final g in Gender.values) Padding(padding: const EdgeInsets.only(right: 8), child: KChip(tr('gender_${g.name}'), selected: _look.gender == g, onTap: () => setState(() => _look = _look.copyWith(gender: g))))]),
        title('${tr('mood_auto')} · ${tr('mood_auto_hint')}'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          KChip(tr('mood_auto'), selected: _look.mood == null, onTap: () => setState(() => _look = _look.copyWith(autoMood: true))),
          for (final m in Mood.values) KChip('${m.emoji} ${m.label}', selected: _look.mood == m, onTap: () => setState(() => _look = _look.copyWith(mood: m))),
        ]),
        title(tr('skin_tone')),
        dots(skinTones, _look.skinTone, (i) => setState(() => _look = _look.copyWith(skinTone: i))),
        title(tr('hair_colour')),
        dots(hairColors, _look.hairColor, (i) => setState(() => _look = _look.copyWith(hairColor: i))),
        title(tr('face_shape')),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final f in FaceShape.values) KChip(tr('face_${f.name}'), selected: _look.faceShape == f, onTap: () => setState(() => _look = _look.copyWith(faceShape: f)))]),
        if (_look.gender == Gender.male) ...[
          title(tr('beard')),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final b in Beard.values) KChip(tr(b.labelKey), selected: _look.beard == b, onTap: () => setState(() => _look = _look.copyWith(beard: b)))]),
        ],
        title(tr('hair_style')),
        items(RewardKind.hair, _look.hairId, (id) => _look.copyWith(hairId: id)),
        title(tr('outfit')),
        items(RewardKind.outfit, _look.outfitId, (id) => _look.copyWith(outfitId: id)),
        title(tr('accessory')),
        items(RewardKind.accessory, _look.accessoryId, (id) => _look.copyWith(accessoryId: id)),
      ],
    );
  }
}
