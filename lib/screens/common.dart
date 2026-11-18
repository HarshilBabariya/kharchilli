import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'categories.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile(this.expense, {super.key});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cat = app.category(expense.category);
    return Pressable(
      scale: 0.98,
      onTap: () => open(context, AddExpenseScreen(editing: expense), rise: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          IconTile(cat.icon, color: cat.tint, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.title.isEmpty ? cat.name : expense.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
              const SizedBox(height: 2),
              Text('${cat.name} · ${app.memberName(expense.paidBy)} · ${expense.mode.label}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
            ]),
          ),
          const SizedBox(width: 10),
          Text(Fmt.ledger(expense.amount), style: context.tt.titleMedium!.copyWith(color: expense.isCredit ? good : context.cs.onSurface, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class MemberChip extends StatelessWidget {
  const MemberChip(this.member, {super.key, required this.selected, required this.onTap});
  final Member member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
        decoration: BoxDecoration(color: selected ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AvatarView(member.avatar, size: 30, ring: false),
          const SizedBox(width: 8),
          Text(member.name, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: selected ? Colors.white : cs.onSurface)),
        ]),
      ),
    );
  }
}

/// A grid of every category; returns the picked key.
Future<String?> pickCategory(BuildContext context, {String? selected}) {
  return showKSheet<String>(
    context,
    title: tr('category'),
    builder: (sheet) {
      final app = AppScope.of(sheet);
      return Column(children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.78,
          children: [
            for (final c in app.sortedCategories)
              Pressable(
                scale: 0.9,
                onTap: () => Navigator.of(sheet).pop(c.key),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.key == selected ? c.tint : Colors.transparent, width: 2.5)),
                    child: IconTile(c.icon, color: c.tint, size: 52),
                  ),
                  const SizedBox(height: 6),
                  Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: sheet.tt.labelSmall!.copyWith(color: sheet.cs.onSurface)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 8),
        KButton(tr('manage_categories'), tonal: true, icon: Icons.tune_rounded, onTap: () {
          Navigator.of(sheet).pop();
          open(context, const CategoriesScreen());
        }),
      ]);
    },
  );
}

/// One number, typed on the money keypad.
Future<double?> askAmount(BuildContext context, {required String title, double? initial, String? removeLabel}) {
  var text = initial == null || initial <= 0 ? '' : Fmt.number(initial).replaceAll(',', '');
  return showKSheet<double>(
    context,
    title: title,
    builder: (sheet) => StatefulBuilder(
      builder: (_, setState) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: FittedBox(child: Text('${Fmt.symbol}${text.isEmpty ? '0' : text}', style: sheet.tt.displaySmall!.copyWith(color: text.isEmpty ? sheet.cs.onSurfaceVariant : sheet.cs.onSurface))),
        ),
        AmountKeypad(value: text, onChanged: (v) => setState(() => text = v)),
        const SizedBox(height: 14),
        KButton(tr('save'), onTap: (double.tryParse(text) ?? 0) > 0 ? () => Navigator.of(sheet).pop(double.parse(text)) : null),
        if (removeLabel != null && (initial ?? 0) > 0) ...[
          const SizedBox(height: 8),
          KButton(removeLabel, tonal: true, danger: true, onTap: () => Navigator.of(sheet).pop(0.0)),
        ],
      ]),
    ),
  );
}
