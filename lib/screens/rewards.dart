import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/charts.dart';
import '../ui/effects.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late int _tab = widget.initialTab;
  RewardKind _kind = RewardKind.theme;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final level = app.level;
    final statuses = app.badgeStatuses;
    final earned = statuses.where((b) => b.earned).length;
    final white80 = Colors.white.withValues(alpha: 0.8);
    return KPage(
      title: tr('rewards'),
      children: [
        KCard(
          gradient: context.heroGradient,
          radius: 32,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('points_to_spend'), style: TextStyle(color: white80, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Coin(size: 34),
                    const SizedBox(width: 10),
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CountUp(s.points.toDouble(), style: context.tt.displaySmall!.copyWith(color: Colors.white), format: (v) => Fmt.number(v)))),
                  ]),
                ]),
              ),
              const SizedBox(width: 12),
              RingChart(
                progress: level.progress(s.lifetimePoints),
                size: 84,
                stroke: 9,
                color: Colors.white,
                trackColor: Colors.white.withValues(alpha: 0.22),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${level.level}', style: context.tt.headlineSmall!.copyWith(color: Colors.white)),
                  Text(tr('stat_level'), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text(tr('lifetime_level', [s.lifetimePoints, level.level, level.title]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(tr('xp_to_next', [level.nextAt - s.lifetimePoints, level.level + 1]), style: TextStyle(color: white80, fontSize: 12.5)),
            const SizedBox(height: 14),
            Row(children: [
              Flame(size: 26, lit: app.streak > 0),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('toast_streak', [app.streak]), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              Text(tr('streak_next', [StreakMilestones.next(app.streak)]), style: TextStyle(color: white80, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Segmented<int>(options: {0: tr('points_history'), 1: tr('badges_count', [earned, statuses.length]), 2: tr('shop')}, value: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 6),
        if (_tab == 0) ..._history(context, app),
        if (_tab == 1) ..._badges(context, statuses),
        if (_tab == 2) ..._shop(context, app),
      ],
    );
  }

  List<Widget> _history(BuildContext context, AppState app) {
    final entries = app.ledger.reversed.take(80).toList();
    return [
      const SizedBox(height: 10),
      if (entries.isEmpty) EmptyState(art: 'trophy', title: tr('points_history'), body: tr('first_expense_hint')),
      if (entries.isNotEmpty)
        KCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  IconTile(e.delta >= 0 ? Icons.add_rounded : Icons.shopping_bag_rounded, color: e.delta >= 0 ? good : context.cs.primary, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(PointReasons.describe(e.reason), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                      Text(Fmt.date(DateTime.fromMillisecondsSinceEpoch(e.at), 'd MMM, h:mm a'), style: context.tt.bodySmall),
                    ]),
                  ),
                  Pill('${e.delta >= 0 ? '+' : ''}${e.delta}', color: e.delta >= 0 ? good : bad),
                ]),
              ),
          ]),
        ),
    ];
  }

  List<Widget> _badges(BuildContext context, List<BadgeStatus> statuses) {
    Widget grid(List<BadgeStatus> list) => GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          childAspectRatio: 0.66,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [for (final b in list) _BadgeTile(b)],
        );
    final earned = statuses.where((b) => b.earned).toList();
    final easy = statuses.where((b) => !b.earned && !b.badge.hard).toList();
    final hard = statuses.where((b) => !b.earned && b.badge.hard).toList();
    return [
      if (earned.isNotEmpty) ...[SectionTitle(tr('badges_earned', [earned.length])), grid(earned)],
      if (easy.isNotEmpty) ...[SectionTitle(tr('badges_easy', [easy.length])), grid(easy)],
      if (hard.isNotEmpty) ...[SectionTitle(tr('badges_hard', [hard.length])), grid(hard)],
    ];
  }

  List<Widget> _shop(BuildContext context, AppState app) {
    final me = app.me;
    final pack = app.festival?.festival.pack;
    final items = RewardCatalog.ofKind(_kind).where((i) => i.pack == null || i.pack == pack || app.isUnlocked(i.id)).toList();

    AvatarConfig wearing(AvatarConfig look, RewardItem item) => switch (item.kind) {
          RewardKind.outfit => look.copyWith(outfitId: item.id),
          RewardKind.hair => look.copyWith(hairId: item.id),
          _ => look.copyWith(accessoryId: item.id),
        };

    Future<void> act(RewardItem item) async {
      if (!app.isUnlocked(item.id)) {
        final ok = await app.unlock(item);
        if (!context.mounted) return;
        if (!ok) {
          toast(context, item.pack != null ? tr('pack_only', [item.pack!.label]) : tr('need_more_points', [item.cost - app.settings.points, item.name]));
          return;
        }
        HapticFeedback.heavyImpact();
        toast(context, tr('unlocked_msg', [item.name]));
      }
      if (item.kind == RewardKind.theme) {
        await app.applyTheme(item.id);
      } else if (me != null && item.kind != RewardKind.feature) {
        me.avatar = wearing(me.avatar, item);
        await app.updateMember(me);
      }
    }

    bool active(RewardItem i) => switch (i.kind) {
          RewardKind.theme => app.activeThemeId == i.id,
          RewardKind.outfit => me?.avatar.outfitId == i.id,
          RewardKind.hair => me?.avatar.hairId == i.id,
          RewardKind.accessory => me?.avatar.accessoryId == i.id,
          RewardKind.feature => app.isUnlocked(i.id),
        };

    return [
      const SizedBox(height: 12),
      SizedBox(
        height: 42,
        child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
          for (final k in RewardKind.values) Padding(padding: const EdgeInsets.only(right: 8), child: KChip(tr(k.labelKey), selected: _kind == k, onTap: () => setState(() => _kind = k))),
        ]),
      ),
      const SizedBox(height: 14),
      if (_kind == RewardKind.feature || me == null)
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KCard(
              padding: const EdgeInsets.all(14),
              onTap: () => act(item),
              child: Row(children: [
                const Sticker('forecast', size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                    Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
                  ]),
                ),
                const SizedBox(width: 8),
                if (active(item)) Pill(tr('unlocked'), color: good) else Pill('${item.cost}', icon: const Coin(size: 14), color: app.settings.points >= item.cost ? context.cs.primary : context.cs.onSurfaceVariant),
              ]),
            ),
          )
      else
        GridView.count(
          crossAxisCount: _kind == RewardKind.theme ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: _kind == RewardKind.theme ? 0.92 : 0.78,
          children: [
            for (final item in items)
              RewardTile(
                item,
                preview: _kind == RewardKind.theme ? ThemePreview(item.id) : AvatarView(wearing(me.avatar, item).copyWith(mood: Mood.happy), size: 62),
                active: active(item),
                activeLabel: _kind == RewardKind.theme ? tr('active') : tr('wearing'),
                onTap: () => act(item),
              ),
          ],
        ),
    ];
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.status);
  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final b = status.badge;
    return Pressable(
      scale: 0.92,
      onTap: () => showKSheet<void>(
        context,
        title: b.name,
        builder: (sheet) => Column(children: [
          Medal(b.id, size: 150, locked: !status.earned, progress: status.fraction),
          const SizedBox(height: 14),
          Text(b.description, textAlign: TextAlign.center, style: sheet.tt.titleMedium),
          const SizedBox(height: 12),
          if (status.earned)
            Pill(tr('earned_on', [Fmt.date(DateTime.fromMillisecondsSinceEpoch(status.earnedAt!), 'd MMM yyyy'), b.bonus]), color: good, icon: const Icon(Icons.verified_rounded, size: 15, color: good))
          else ...[
            KProgress(status.fraction, height: 9),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(tr('progress_of', [status.progress.clamp(0, b.target), b.target, tr(b.unitKey)]), style: sheet.tt.bodySmall)),
              const Coin(size: 14),
              const SizedBox(width: 4),
              Text(tr('reward_points', [b.bonus]), style: sheet.tt.bodySmall),
            ]),
          ],
          const SizedBox(height: 18),
          Align(alignment: Alignment.centerLeft, child: Text(tr('how_to_earn'), style: sheet.tt.labelMedium)),
          for (final (i, step) in b.howTo.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: sheet.cs.primaryContainer, shape: BoxShape.circle), child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: sheet.cs.primary))),
                const SizedBox(width: 10),
                Expanded(child: Text(step, style: sheet.tt.bodyMedium)),
              ]),
            ),
        ]),
      ),
      child: KCard(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Medal(b.id, size: 64, locked: !status.earned, progress: status.fraction),
          const SizedBox(height: 8),
          Text(b.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall!.copyWith(color: context.cs.onSurface, height: 1.2)),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [const Coin(size: 11), const SizedBox(width: 3), Text('${b.bonus}', style: context.tt.labelSmall!.copyWith(fontSize: 10))]),
        ]),
      ),
    );
  }
}
