import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../ui/avatar.dart';
import '../ui/charts.dart';
import '../ui/effects.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

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
    final tabs = [tr('points_history'), tr('badges_count', [earned, statuses.length]), tr('shop')];
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
                  Text(tr('points_to_spend'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                  CountUp(s.points.toDouble(), style: context.tt.displaySmall!.copyWith(color: Colors.white), format: (v) => '⭐ ${Fmt.number(v)}'),
                ]),
              ),
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
            const SizedBox(height: 10),
            Text(tr('lifetime_level', [s.lifetimePoints, level.level, level.title]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(tr('xp_to_next', [level.nextAt - s.lifetimePoints, level.level + 1]), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
            const SizedBox(height: 14),
            Row(children: [
              Flame(size: 26, lit: app.streak > 0),
              const SizedBox(width: 8),
              Text(tr('toast_streak', [app.streak]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              Pill(tr('streak_next', [StreakMilestones.next(app.streak)]), onDark: true),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: context.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Pressable(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _tab == i ? context.cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                    child: FittedBox(child: Text(tabs[i], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _tab == i ? Colors.white : context.cs.onSurfaceVariant))),
                  ),
                ),
              ),
          ]),
        ),
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
      if (entries.isEmpty) EmptyState(emoji: '⭐', title: tr('points_history'), body: tr('first_expense_hint')),
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
          childAspectRatio: 0.78,
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

    Future<void> act(RewardItem item) async {
      if (!app.isUnlocked(item.id)) {
        final ok = await app.unlock(item);
        if (!context.mounted) return;
        if (!ok) {
          toast(context, tr('need_more_points', [item.cost - app.settings.points, item.name]));
          return;
        }
        HapticFeedback.heavyImpact();
        toast(context, tr('unlocked_msg', [item.emoji, item.name]));
      }
      if (item.kind == RewardKind.theme) {
        await app.applyTheme(item.id);
      } else if (me != null && item.kind != RewardKind.feature) {
        me.avatar = switch (item.kind) {
          RewardKind.outfit => me.avatar.copyWith(outfitId: item.id),
          RewardKind.hair => me.avatar.copyWith(hairId: item.id),
          _ => me.avatar.copyWith(accessoryId: item.id),
        };
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
      const SizedBox(height: 12),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: KCard(
            padding: const EdgeInsets.all(14),
            onTap: () => act(item),
            child: Row(children: [
              if (item.kind == RewardKind.theme)
                _Swatch(item.id)
              else if (item.kind == RewardKind.feature || me == null)
                IconTile(null, emoji: item.emoji, size: 54)
              else
                AvatarView(switch (item.kind) { RewardKind.outfit => me.avatar.copyWith(outfitId: item.id), RewardKind.hair => me.avatar.copyWith(hairId: item.id), _ => me.avatar.copyWith(accessoryId: item.id) }, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${item.emoji} ${item.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
                ]),
              ),
              const SizedBox(width: 8),
              if (active(item))
                Pill(item.kind == RewardKind.feature ? tr('unlocked') : item.kind == RewardKind.theme ? tr('active') : tr('wearing'), color: good)
              else if (app.isUnlocked(item.id))
                Pill(item.kind == RewardKind.theme ? tr('apply') : tr('wear'))
              else if (item.pack != null)
                Pill(tr('claim_free'), color: const Color(0xFFFB8C00))
              else
                Pill('⭐ ${item.cost}', color: app.settings.points >= item.cost ? context.cs.primary : context.cs.onSurfaceVariant),
            ]),
          ),
        ),
    ];
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.themeId);
  final String themeId;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(themeId);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(p.primary), Color(p.secondary), Color(p.tertiary)])),
    );
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
          RingChart(progress: status.fraction, size: 132, color: status.earned ? good : sheet.cs.primary, child: Text(b.emoji, style: const TextStyle(fontSize: 56))),
          const SizedBox(height: 12),
          Text(b.description, textAlign: TextAlign.center, style: sheet.tt.titleMedium),
          const SizedBox(height: 6),
          Text(
            status.earned ? tr('earned_on', [Fmt.date(DateTime.fromMillisecondsSinceEpoch(status.earnedAt!), 'd MMM yyyy'), b.bonus]) : '${tr('progress_of', [status.progress.clamp(0, b.target), b.target, tr(b.unitKey)])} · ${tr('reward_points', [b.bonus])}',
            textAlign: TextAlign.center,
            style: sheet.tt.bodySmall,
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          RingChart(progress: status.fraction, size: 58, stroke: 5, color: status.earned ? good : context.cs.primary, child: Opacity(opacity: status.earned ? 1 : 0.45, child: Text(b.emoji, style: const TextStyle(fontSize: 26)))),
          const SizedBox(height: 8),
          Text(b.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall!.copyWith(color: context.cs.onSurface)),
          Text(tr('badge_points_total', [b.bonus]), style: context.tt.labelSmall!.copyWith(fontSize: 10)),
        ]),
      ),
    );
  }
}
