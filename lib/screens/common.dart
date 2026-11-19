import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
                  Stack(clipBehavior: Clip.none, children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: c.key == selected ? sheet.cs.onSurface : Colors.transparent, width: 2.5)),
                      child: IconTile(c.icon, color: c.tint, size: 52),
                    ),
                    if (c.key == selected)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          decoration: BoxDecoration(color: sheet.cs.surface, shape: BoxShape.circle),
                          child: Icon(Icons.check_circle_rounded, size: 22, color: sheet.cs.onSurface),
                        ),
                      ),
                  ]),
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

/// Asks for one line of text.
Future<String?> askText(BuildContext context, String title, String label, String hint, {String initial = ''}) {
  final text = TextEditingController(text: initial);
  return showKSheet<String>(
    context,
    title: title,
    builder: (sheet) => StatefulBuilder(
      builder: (_, setState) => Column(children: [
        KField(controller: text, label: label, hint: hint, autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        KButton(tr('save'), onTap: text.text.trim().isEmpty ? null : () => Navigator.of(sheet).pop(text.text.trim())),
      ]),
    ),
  );
}

/// A sheet to take, choose, view or remove a photo kept in the app's documents folder. Answers the new file name,
/// an empty string when the photo was removed, or null when nothing changed.
Future<String?> pickPhoto(BuildContext context, {required String title, required String current}) {
  final app = AppScope.read(context);
  return showKSheet<String>(
    context,
    title: title,
    builder: (sheet) {
      Future<void> pick(ImageSource source) async {
        final nav = Navigator.of(sheet);
        try {
          final shot = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
          if (shot == null) return;
          final name = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(shot.path).copy('${app.photosDir}/$name');
          nav.pop(name);
        } catch (_) {
          nav.pop();
          if (context.mounted) toast(context, tr('photo_failed'));
        }
      }

      return Column(children: [
        if (current.isNotEmpty) ...[
          ClipRRect(borderRadius: BorderRadius.circular(18), child: InteractiveViewer(child: Image.file(File('${app.photosDir}/$current'), height: 320, fit: BoxFit.contain))),
          const SizedBox(height: 14),
        ],
        Row(children: [
          Expanded(child: KButton(tr('photo_camera'), icon: Icons.photo_camera_rounded, onTap: () => pick(ImageSource.camera))),
          const SizedBox(width: 10),
          Expanded(child: KButton(tr('photo_gallery'), tonal: true, icon: Icons.photo_library_rounded, onTap: () => pick(ImageSource.gallery))),
        ]),
        if (current.isNotEmpty) ...[
          const SizedBox(height: 8),
          KButton(tr('remove'), tonal: true, danger: true, onTap: () => Navigator.of(sheet).pop('')),
        ],
      ]);
    },
  );
}

/// A shop item as a grid tile: its preview, name and whether it is owned, in use, free or priced.
class RewardTile extends StatelessWidget {
  const RewardTile(this.item, {super.key, required this.preview, required this.active, required this.activeLabel, required this.onTap});
  final RewardItem item;
  final Widget preview;
  final bool active;
  final String activeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final owned = app.isUnlocked(item.id);
    final small = context.tt.labelSmall!.copyWith(fontSize: 10.5);
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: active ? cs.primary : cs.outlineVariant, width: active ? 2.5 : 1)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            preview,
            if (!owned) Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle, border: Border.all(color: cs.outlineVariant)), child: Icon(Icons.lock_rounded, size: 12, color: cs.onSurfaceVariant))),
          ]),
          const SizedBox(height: 8),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.labelSmall!.copyWith(color: cs.onSurface)),
          const SizedBox(height: 3),
          if (owned)
            Text(active ? activeLabel : tr('owned'), maxLines: 1, overflow: TextOverflow.ellipsis, style: small.copyWith(color: active ? good : null))
          else if (item.pack != null)
            Text(tr('claim_free'), maxLines: 1, overflow: TextOverflow.ellipsis, style: small.copyWith(color: const Color(0xFFFB8C00)))
          else
            Row(mainAxisSize: MainAxisSize.min, children: [const Coin(size: 12), const SizedBox(width: 3), Text('${item.cost}', style: small.copyWith(color: app.settings.points >= item.cost ? cs.onSurface : null))]),
        ]),
      ),
    );
  }
}
