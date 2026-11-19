import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

const _tips = <(IconData, int)>[(Icons.apps_rounded, 0xFF7C4DFF), (Icons.swipe_rounded, 0xFF039BE5), (Icons.widgets_rounded, 0xFF43A047), (Icons.mic_rounded, 0xFFFF7043)];

/// A few tips shown once after setup, one at a time; Settings can replay them.
Future<void> showTour(BuildContext context) async {
  final app = AppScope.read(context);
  var step = 0;
  await showKSheet<void>(
    context,
    title: tr('tour_title'),
    builder: (sheet) => StatefulBuilder(
      builder: (_, setState) {
        final (icon, color) = _tips[step];
        final last = step == _tips.length - 1;
        return Column(children: [
          IconTile(icon, color: Color(color), size: 72),
          const SizedBox(height: 16),
          Text(tr('tour_${step + 1}_title'), textAlign: TextAlign.center, style: sheet.tt.titleLarge),
          const SizedBox(height: 6),
          Text(tr('tour_${step + 1}_body'), textAlign: TextAlign.center, style: sheet.tt.bodyMedium!.copyWith(color: sheet.cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _tips.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == step ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: i == step ? sheet.cs.primary : sheet.cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          const SizedBox(height: 18),
          KButton(tr(last ? 'tour_done' : 'tour_next'), onTap: () {
            if (last) {
              Navigator.of(sheet).pop();
            } else {
              setState(() => step++);
            }
          }),
          if (!last) ...[const SizedBox(height: 8), KButton(tr('tour_skip'), tonal: true, onTap: () => Navigator.of(sheet).pop())],
        ]);
      },
    ),
  );
  await app.setTourSeen();
}
