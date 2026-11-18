import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

enum _Tab { face, hair, outfit, extras }

class AvatarStudioScreen extends StatefulWidget {
  const AvatarStudioScreen(this.member, {super.key});
  final Member member;

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  late AvatarConfig _look = widget.member.avatar;
  _Tab _tab = _Tab.face;
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

  void _set(AvatarConfig next) => setState(() => _look = next);

  Future<void> _choose(RewardItem item, AvatarConfig next) async {
    final app = AppScope.read(context);
    if (!app.isUnlocked(item.id)) {
      final ok = await app.unlock(item);
      if (!mounted) return;
      if (!ok) {
        toast(context, item.pack != null ? tr('pack_only', [item.pack!.label]) : tr('need_more_points', [item.cost - app.settings.points, item.name]));
        return;
      }
      toast(context, tr('unlocked_msg', [item.name]));
    }
    _set(next);
    _play(AvatarAction.spin);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final inset = MediaQuery.viewPaddingOf(context).bottom;

    Widget heading(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 10), child: Text(text, style: context.tt.labelMedium));
    Widget swatches(List<int> colours, int selected, ValueChanged<int> pick) => Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < colours.length; i++)
            Pressable(
              scale: 0.8,
              onTap: () => pick(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected == i ? cs.primary : Colors.transparent, width: 2.5)),
                child: DecoratedBox(decoration: BoxDecoration(color: Color(colours[i]), shape: BoxShape.circle)),
              ),
            ),
        ]);
    Widget items(RewardKind kind, String current, AvatarConfig Function(String id) apply) => GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: [
            for (final item in RewardCatalog.ofKind(kind).where((i) => i.pack == null || i.pack == app.festival?.festival.pack || app.isUnlocked(i.id)))
              RewardTile(item, preview: AvatarView(apply(item.id).copyWith(mood: Mood.happy), size: 62), active: current == item.id, activeLabel: tr('wearing'), onTap: () => _choose(item, apply(item.id))),
          ],
        );

    final List<Widget> panel = switch (_tab) {
      _Tab.face => [
          heading(tr('gender')),
          Segmented<Gender>(options: {for (final g in Gender.values) g: tr('gender_${g.name}')}, value: _look.gender, onChanged: (g) => _set(_look.copyWith(gender: g))),
          heading(tr('skin_tone')),
          swatches(skinTones, _look.skinTone, (i) => _set(_look.copyWith(skinTone: i))),
          heading(tr('face_shape')),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final f in FaceShape.values) KChip(tr('face_${f.name}'), selected: _look.faceShape == f, onTap: () => _set(_look.copyWith(faceShape: f)))]),
          heading(tr('mood_auto_hint')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            KChip(tr('mood_auto'), icon: Icons.auto_mode_rounded, selected: _look.mood == null, onTap: () => _set(_look.copyWith(autoMood: true))),
            for (final m in Mood.values) KChip(m.label, icon: moodIcon(m), selected: _look.mood == m, onTap: () => _set(_look.copyWith(mood: m))),
          ]),
        ],
      _Tab.hair => [
          heading(tr('hair_colour')),
          swatches(hairColors, _look.hairColor, (i) => _set(_look.copyWith(hairColor: i))),
          if (_look.gender == Gender.male) ...[
            heading(tr('beard')),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final b in Beard.values) KChip(tr(b.labelKey), selected: _look.beard == b, onTap: () => _set(_look.copyWith(beard: b)))]),
          ],
          heading(tr('hair_style')),
          items(RewardKind.hair, _look.hairId, (id) => _look.copyWith(hairId: id)),
        ],
      _Tab.outfit => [const SizedBox(height: 14), items(RewardKind.outfit, _look.outfitId, (id) => _look.copyWith(outfitId: id))],
      _Tab.extras => [const SizedBox(height: 14), items(RewardKind.accessory, _look.accessoryId, (id) => _look.copyWith(accessoryId: id))],
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Backdrop(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                RoundIcon(Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(child: Text(tr('avatar_of', [widget.member.name]), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.headlineSmall)),
                Pill(Fmt.number(app.settings.points), icon: const Coin(size: 16)),
              ]),
            ),
            const SizedBox(height: 8),
            AvatarView(_look.copyWith(mood: _look.mood ?? app.mood), key: ValueKey(_plays), size: 168, animate: true, action: _action),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                for (final a in AvatarAction.values) Padding(padding: const EdgeInsets.only(right: 8), child: KChip(a.label, icon: actionIcon(a), selected: _action == a, onTap: () => _play(a))),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Segmented<_Tab>(
                options: {_Tab.face: tr('look_face'), _Tab.hair: tr('kind_hair'), _Tab.outfit: tr('kind_outfits'), _Tab.extras: tr('kind_accessories')},
                value: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: ListView(key: ValueKey(_tab), padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), physics: const BouncingScrollPhysics(), children: panel),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 16),
              child: KButton(tr('save_look'), icon: Icons.check_rounded, onTap: () async {
                final nav = Navigator.of(context);
                widget.member.avatar = _look;
                nav.pop();
                await app.updateMember(widget.member);
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
