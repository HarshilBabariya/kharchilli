import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('categories'),
      bottom: KButton(tr('new_category'), icon: Icons.add_rounded, onTap: () => _edit(context, null)),
      children: [
        Text(tr('categories_hint'), style: context.tt.bodySmall),
        const SizedBox(height: 12),
        KCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            for (final c in app.sortedCategories)
              NavRow(icon: c.icon, color: c.tint, title: c.name, subtitle: c.builtIn ? tr('built_in') : tr('custom'), onTap: () => _edit(context, c)),
          ]),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, Category? existing) async {
    final app = AppScope.read(context);
    final name = TextEditingController(text: existing?.customName ?? '');
    var icon = existing?.iconKey ?? 'gift';
    var colour = existing?.color ?? categoryColors[10];
    var hue = HSVColor.fromColor(Color(colour)).hue;
    await showKSheet<void>(
      context,
      title: existing == null ? tr('new_category') : tr('edit_category'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: IconTile(CategoryIcons.of(icon), color: Color(colour), size: 72)),
          const SizedBox(height: 14),
          if (existing == null || !existing.builtIn) KField(controller: name, label: tr('category_name'), hint: tr('category_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          Text(tr('icon'), style: sheet.tt.labelMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final key in CategoryIcons.byKey.keys)
              Pressable(
                scale: 0.85,
                onTap: () => setState(() => icon = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: icon == key ? Color(colour) : sheet.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                  child: Icon(CategoryIcons.of(key), size: 22, color: icon == key ? Colors.white : sheet.cs.onSurfaceVariant),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text(tr('colour'), style: sheet.tt.labelMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in categoryColors)
              Pressable(
                scale: 0.8,
                onTap: () => setState(() => colour = c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: colour == c ? sheet.cs.onSurface : Colors.transparent, width: 2.5)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Text(tr('custom_colour'), style: sheet.tt.labelMedium),
          Slider(
            value: hue,
            max: 360,
            activeColor: Color(colour),
            onChanged: (v) => setState(() {
              hue = v;
              colour = HSVColor.fromAHSV(1, v, 0.72, 0.9).toColor().toARGB32();
            }),
          ),
          const SizedBox(height: 8),
          KButton(tr('save'), onTap: existing != null && existing.builtIn || name.text.trim().isNotEmpty
              ? () async {
                  final nav = Navigator.of(sheet);
                  final c = existing ?? Category(key: 'custom_${DateTime.now().millisecondsSinceEpoch}', iconKey: icon, color: colour);
                  c
                    ..customName = existing != null && existing.builtIn ? '' : name.text
                    ..iconKey = icon
                    ..color = colour;
                  await app.saveCategory(c);
                  nav.pop();
                }
              : null),
          if (existing != null && !existing.builtIn) ...[
            const SizedBox(height: 8),
            KButton(tr('delete_category'), tonal: true, danger: true, onTap: () async {
              final nav = Navigator.of(sheet);
              if (await confirm(sheet, title: tr('delete_category_q', [existing.name]), body: tr('delete_category_body'), action: tr('delete'))) {
                await app.deleteCategory(existing);
                nav.pop();
              }
            }),
          ],
        ]),
      ),
    );
  }
}
