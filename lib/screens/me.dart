import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/effects.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'avatar_studio.dart';
import 'budgets.dart';
import 'categories.dart';
import 'expenses.dart';
import 'export.dart';
import 'family.dart';
import 'household.dart';
import 'insights.dart';
import 'lock.dart';
import 'reminders.dart';
import 'rewards.dart';

const appVersion = '1.1.0';

class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final me = app.me;
    final level = app.level;
    Widget section(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(title),
          KCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: rows)),
        ]);
    Widget toggle(IconData icon, String title, String? subtitle, bool value, void Function(Settings, bool) set, {Color? color}) =>
        NavRow(icon: icon, color: color, title: title, subtitle: subtitle, trailing: KSwitch(value: value, onChanged: (v) => app.updateSettings((x) => set(x, v))));

    return KPage(
      title: tr('tab_me'),
      children: [
        if (me != null)
          KCard(
            gradient: context.heroGradient,
            radius: 32,
            onTap: () => open(context, AvatarStudioScreen(me)),
            child: Column(children: [
              Row(children: [
                AvatarView(app.myLook, size: 84, animate: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.headlineSmall!.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Pill(tr('xp_level_label', [level.level, level.title]), onDark: true),
                    const SizedBox(height: 6),
                    Text(tr('change_look'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                for (final (i, stat) in [
                  (const Coin(size: 22), Fmt.number(s.points), tr('stat_points')),
                  (Flame(size: 22, lit: app.streak > 0), '${app.streak}', tr('stat_streak')),
                  (const Icon(Icons.military_tech_rounded, color: Colors.white, size: 22), '${level.level}', tr('stat_level')),
                ].indexed)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
                      child: Column(children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          stat.$1,
                          const SizedBox(width: 6),
                          Flexible(child: Text(stat.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge!.copyWith(color: Colors.white))),
                        ]),
                        const SizedBox(height: 2),
                        Text(stat.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
        section(tr('household'), [
          NavRow(icon: Icons.emoji_events_rounded, color: const Color(0xFFFFB300), title: tr('rewards'), subtitle: tr('rewards_sub'), onTap: () => open(context, const RewardsScreen())),
          NavRow(icon: Icons.family_restroom_rounded, color: const Color(0xFF7C4DFF), title: tr('family_members'), subtitle: trPlural('family_sub', app.members.length), onTap: () => open(context, const FamilyScreen())),
          NavRow(icon: Icons.track_changes_rounded, color: good, title: tr('budgets'), subtitle: tr('budgets_sub'), onTap: () => open(context, const BudgetsScreen())),
          NavRow(icon: Icons.notifications_active_rounded, color: const Color(0xFFFB8C00), title: tr('reminders_bills'), subtitle: tr('reminders_sub'), onTap: () => open(context, const RemindersScreen())),
          NavRow(icon: Icons.category_rounded, color: const Color(0xFF039BE5), title: tr('categories'), subtitle: tr('categories_sub'), onTap: () => open(context, const CategoriesScreen())),
        ]),
        section(tr('views'), [
          NavRow(icon: Icons.insights_rounded, color: const Color(0xFFEC407A), title: tr('insights'), subtitle: tr('insights_sub'), onTap: () => open(context, const InsightsScreen())),
          NavRow(icon: Icons.calendar_month_rounded, color: const Color(0xFF26A69A), title: tr('calendar'), onTap: () => open(context, const CalendarScreen())),
        ]),
        section(tr('household_money'), [
          NavRow(icon: Icons.storefront_rounded, color: const Color(0xFF8D6E63), title: tr('khata'), subtitle: tr('khata_sub'), onTap: () => open(context, const KhataScreen())),
          NavRow(icon: Icons.local_drink_rounded, color: const Color(0xFF29B6F6), title: tr('services'), subtitle: tr('services_sub'), onTap: () => open(context, const ServicesScreen())),
          NavRow(icon: Icons.diamond_rounded, color: const Color(0xFFFFB300), title: tr('savings'), subtitle: tr('savings_sub'), onTap: () => open(context, const SavingsScreen())),
        ]),
        section(tr('appearance'), [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Segmented<ThemeModeSetting>(options: {for (final m in ThemeModeSetting.values) m: tr('mode_${m.name}')}, value: s.themeMode, onChanged: (m) => app.updateSettings((x) => x.themeMode = m)),
          ),
          NavRow(icon: Icons.palette_rounded, color: const Color(0xFFEC407A), title: tr('kind_themes'), subtitle: RewardCatalog.find(app.activeThemeId)?.name, onTap: () => open(context, const RewardsScreen(initialTab: 2))),
          NavRow(icon: Icons.translate_rounded, title: tr('language'), subtitle: L10n.languages[s.language], onTap: () => _language(context)),
          toggle(Icons.celebration_rounded, tr('festive_mode'), tr('festive_mode_sub'), s.festiveMode, (x, v) => x.festiveMode = v, color: const Color(0xFFFF7043)),
          toggle(Icons.volume_up_rounded, tr('sound_effects'), null, s.soundEffects, (x, v) => x.soundEffects = v, color: const Color(0xFF26A69A)),
        ]),
        section(tr('notifications'), [
          toggle(Icons.speed_rounded, tr('budget_alerts'), tr('budget_alerts_sub'), s.budgetAlerts, (x, v) => x.budgetAlerts = v),
          toggle(Icons.alarm_rounded, tr('reminders_bills'), tr('reminder_notifs_sub'), s.reminderNotifs, (x, v) => x.reminderNotifs = v),
          toggle(Icons.military_tech_rounded, tr('rewards'), tr('reward_notifs_sub'), s.rewardNotifs, (x, v) => x.rewardNotifs = v),
        ]),
        if (me != null)
          section(tr('security'), [
            NavRow(
              icon: Icons.lock_rounded,
              title: tr('app_lock'),
              subtitle: s.appLock ? tr('app_lock_on_sub') : tr('app_lock_off_sub'),
              trailing: KSwitch(
                value: s.appLock,
                onChanged: (on) async {
                  if (on && !me.hasPin) {
                    final pin = await askNewPin(context);
                    if (pin == null) return;
                    await app.setPin(me, pin);
                  }
                  await app.setAppLock(on);
                },
              ),
            ),
            NavRow(
              icon: Icons.pin_rounded,
              title: me.hasPin ? tr('change_pin') : tr('set_pin'),
              subtitle: me.hasPin ? tr('pin_protected') : tr('pin_add_hint'),
              onTap: () async {
                final pin = await askNewPin(context);
                if (pin != null) await app.setPin(me, pin);
              },
            ),
            if (me.hasPin) NavRow(icon: Icons.lock_open_rounded, color: bad, title: tr('remove_pin'), onTap: () => app.setPin(me, null)),
          ]),
        section(tr('your_data'), [
          NavRow(icon: Icons.ios_share_rounded, title: tr('export_data'), subtitle: tr('export_sub'), onTap: () => _export(context)),
          NavRow(icon: Icons.file_download_rounded, title: tr('import_csv'), subtitle: tr('import_sub'), onTap: () => importCsvFile(context)),
          NavRow(
            icon: Icons.delete_forever_rounded,
            color: bad,
            title: tr('erase_all'),
            onTap: () async {
              if (await confirm(context, title: tr('erase_all_q'), body: tr('erase_all_body'), action: tr('erase_all_confirm'))) await app.eraseAll();
            },
          ),
        ]),
        section(tr('more_options'), [
          NavRow(icon: Icons.help_rounded, title: tr('faqs'), subtitle: tr('faqs_sub'), onTap: () => _faqs(context)),
          NavRow(icon: Icons.info_rounded, title: tr('about_app'), subtitle: tr('about_sub'), onTap: () => _about(context)),
        ]),
        const SizedBox(height: 18),
        KButton(tr('log_out_switch'), tonal: true, icon: Icons.logout_rounded, onTap: () async {
          if (await confirm(context, title: tr('log_out_q'), body: tr('log_out_body'), action: tr('log_out'), danger: false)) await app.logout();
        }),
      ],
    );
  }

  void _about(BuildContext context) {
    showKSheet<void>(
      context,
      title: tr('about_app'),
      builder: (sheet) => Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/brand/icon.png', width: 84, height: 84)),
        const SizedBox(height: 12),
        Text('Gharcha', style: sheet.tt.headlineSmall),
        const SizedBox(height: 4),
        Pill(tr('version_label', [appVersion])),
        const SizedBox(height: 14),
        Text(tr('about_footer'), textAlign: TextAlign.center, style: sheet.tt.bodyMedium!.copyWith(color: sheet.cs.onSurfaceVariant)),
      ]),
    );
  }

  void _language(BuildContext context) {
    showKSheet<void>(
      context,
      title: tr('language'),
      builder: (sheet) {
        final app = AppScope.of(sheet);
        return Column(children: [
          for (final l in L10n.languages.entries)
            NavRow(
              icon: Icons.translate_rounded,
              title: l.value,
              trailing: app.settings.language == l.key ? Icon(Icons.check_circle_rounded, color: sheet.cs.primary) : const SizedBox(),
              onTap: () {
                Navigator.of(sheet).pop();
                app.setLanguage(l.key);
              },
            ),
        ]);
      },
    );
  }

  void _export(BuildContext context) {
    final app = AppScope.read(context);
    if (!app.isUnlocked(RewardCatalog.export)) {
      final item = RewardCatalog.find(RewardCatalog.export)!;
      toast(context, tr('need_more_points', [item.cost, item.name]));
      open(context, const RewardsScreen(initialTab: 2));
      return;
    }
    final month = Days.today();
    showKSheet<void>(
      context,
      title: tr('export_data'),
      builder: (sheet) => Column(children: [
        for (final scope in [(tr('export_all'), tr('export_all_sub'), null), (Fmt.monthYear(month), tr('export_month_sub'), month)]) ...[
          NavRow(icon: Icons.table_chart_rounded, color: good, title: '${scope.$1} (CSV)', subtitle: scope.$2, onTap: () => shareCsv(app, month: scope.$3)),
          NavRow(icon: Icons.picture_as_pdf_rounded, color: bad, title: '${scope.$1} (PDF)', subtitle: scope.$2, onTap: () => sharePdf(app, month: scope.$3)),
        ],
      ]),
    );
  }

  void _faqs(BuildContext context) {
    showKSheet<void>(
      context,
      title: tr('faqs'),
      builder: (sheet) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 1; i <= 5; i++) ...[
          Text(tr('faq_q$i'), style: sheet.tt.titleMedium),
          const SizedBox(height: 4),
          Text(tr('faq_a$i'), style: sheet.tt.bodyMedium!.copyWith(color: sheet.cs.onSurfaceVariant)),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }
}
