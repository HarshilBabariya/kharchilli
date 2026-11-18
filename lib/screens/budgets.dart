import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../ui/charts.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final today = Days.today();
    final month = app.inMonth(today);
    final spent = app.spentIn(today);
    final progress = app.budgetProgress;
    final tone = progress > 1 ? bad : progress >= 0.8 ? const Color(0xFFFB8C00) : good;
    return KPage(
      title: tr('budgets'),
      subtitle: Fmt.monthYear(today),
      children: [
        KCard(
          onTap: () async {
            final v = await askAmount(context, title: s.monthlyBudget > 0 ? tr('change_budget') : tr('set_monthly_budget'), initial: s.monthlyBudget, removeLabel: tr('remove_limit'));
            if (v != null) await app.setMonthlyBudget(v);
          },
          child: Row(children: [
            RingChart(
              progress: progress,
              size: 104,
              stroke: 12,
              color: tone,
              child: s.monthlyBudget > 0 ? Text('${(progress * 100).round()}%', style: context.tt.headlineSmall) : Icon(Icons.track_changes_rounded, size: 34, color: context.cs.onSurfaceVariant),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('spent_in', [Fmt.month(today)]), style: context.tt.labelSmall),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CountUp(spent, style: context.tt.headlineMedium!)),
                const SizedBox(height: 4),
                Text(
                  s.monthlyBudget <= 0
                      ? tr('set_budget_hint')
                      : progress > 1
                          ? tr('over_budget_by', [Fmt.money(spent - s.monthlyBudget)])
                          : tr('left_of', [Fmt.money(s.monthlyBudget - spent), Fmt.money(s.monthlyBudget)]),
                  style: context.tt.bodySmall!.copyWith(color: s.monthlyBudget > 0 ? tone : null, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Pill(s.monthlyBudget > 0 ? tr('change_budget') : tr('set_monthly_budget')),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          onTap: () async {
            final v = await askAmount(context, title: tr('monthly_income'), initial: s.monthlyIncome, removeLabel: tr('remove'));
            if (v != null) await app.setMonthlyIncome(v);
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const IconTile(Icons.savings_rounded, color: good),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('monthly_income'), style: context.tt.labelSmall),
                  Text(s.monthlyIncome > 0 ? Fmt.money(s.monthlyIncome) : tr('income_hint'), maxLines: 2, overflow: TextOverflow.ellipsis, style: s.monthlyIncome > 0 ? context.tt.titleLarge : context.tt.bodyMedium),
                ]),
              ),
              Icon(Icons.edit_rounded, color: context.cs.onSurfaceVariant),
            ]),
            if (s.monthlyIncome > 0) ...[
              const SizedBox(height: 14),
              KProgress(spent / s.monthlyIncome, color: spent > s.monthlyIncome ? bad : good, height: 9),
              const SizedBox(height: 8),
              Text(
                spent > s.monthlyIncome ? tr('over_income_by', [Fmt.money(spent - s.monthlyIncome)]) : tr('saved_so_far', [Fmt.money(s.monthlyIncome - spent), ((1 - spent / s.monthlyIncome) * 100).round()]),
                style: context.tt.bodySmall!.copyWith(color: spent > s.monthlyIncome ? bad : good, fontWeight: FontWeight.w600),
              ),
            ],
          ]),
        ),
        if (app.forecast != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: KCard(child: Row(children: [const Sticker('forecast', size: 46), const SizedBox(width: 14), Expanded(child: Text(app.forecast!, style: context.tt.bodyMedium))])),
          ),
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(tr('budget_boss_hint'), style: context.tt.bodySmall)),
        SectionTitle(tr('per_category')),
        for (final c in app.sortedCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (_) {
              final limit = s.categoryBudgets[c.key] ?? 0;
              final used = max(AppState.net(month.where((e) => e.category == c.key)), 0.0);
              final ratio = limit <= 0 ? 0.0 : used / limit;
              final colour = ratio > 1 ? bad : ratio >= 0.8 ? const Color(0xFFFB8C00) : c.tint;
              return KCard(
                padding: const EdgeInsets.all(14),
                onTap: () async {
                  final v = await askAmount(context, title: tr('limit_for', [c.name]), initial: limit.toDouble(), removeLabel: tr('remove_limit'));
                  if (v != null) await app.setCategoryBudget(c.key, v);
                },
                child: Column(children: [
                  Row(children: [
                    IconTile(c.icon, color: c.tint, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                        Text(limit <= 0 ? tr('tap_to_set_limit') : '${Fmt.money(used)} ${tr('of_limit', [Fmt.money(limit)])}', style: context.tt.bodySmall),
                      ]),
                    ),
                    if (limit > 0) Pill('${(ratio * 100).round()}%', color: colour),
                  ]),
                  if (limit > 0) ...[const SizedBox(height: 10), KProgress(ratio, color: colour, height: 8)],
                ]),
              );
            }),
          ),
      ],
    );
  }
}
