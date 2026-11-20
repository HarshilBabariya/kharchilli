import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/parsers.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';

/// Payments spotted in bank and UPI message notifications, each waiting to be added or dismissed. Android only.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pending = app.captures.reversed.toList();
    return KPage(
      title: tr('capture'),
      children: [
        KCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Sticker('bell', size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.captureOn ? tr('capture_on') : tr('capture_off'), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: app.captureOn ? good : null)),
                  Text(tr('capture_how'), style: context.tt.bodySmall),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            KButton(
              app.captureOn ? tr('capture_manage') : tr('capture_allow'),
              tonal: app.captureOn,
              icon: Icons.notifications_active_rounded,
              onTap: () => const AndroidIntent(action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS').launch(),
            ),
          ]),
        ),
        if (pending.isEmpty)
          EmptyState(art: 'receipt', title: tr('capture_empty_title'), body: tr('capture_empty_body'))
        else ...[
          SectionTitle(trPlural('capture_pending', pending.length)),
          for (final c in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KCard(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(children: [
                    IconTile(c.amount < 0 ? Icons.south_west_rounded : Icons.north_east_rounded, color: c.amount < 0 ? good : context.cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.merchant.isEmpty ? tr('capture_unknown') : c.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                        Text([if (c.source.isNotEmpty) c.source, Fmt.date(c.date, 'd MMM, h:mm a')].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.bodySmall),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text(Fmt.ledger(c.amount), style: context.tt.titleLarge!.copyWith(color: c.amount < 0 ? good : null)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: KButton(tr('dismiss'), tonal: true, onTap: () => app.dismissCapture(c))),
                    const SizedBox(width: 10),
                    Expanded(child: KButton(tr('add'), icon: Icons.add_rounded, onTap: () => open(context, AddExpenseScreen(draft: VoiceResult(c.amount.abs(), c.merchant, VoiceParser.guessCategory(c.merchant, app.customCategoryNames) ?? BuiltInCategories.other, PaymentMode.upi, null, c.amount < 0), draftDay: c.date, onSaved: () => app.dismissCapture(c)), rise: true))),
                  ]),
                ]),
              ),
            ),
        ],
      ],
    );
  }
}
